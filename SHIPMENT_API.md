# Shipment (Kargo Takip) API Documentation

## Genel Bakış

Kargo takip sistemi, adapter pattern kullanarak birden fazla kargo firması ile entegrasyon sağlar. Her kargo firması için ayrı bir servis adapter'ı bulunur ve kolayca yeni kargo firmaları eklenebilir.

## Mimari

### 1. Adapter Pattern

```
CargoService (Base)
  ├── PttService
  ├── ArasService
  ├── YurticiService
  ├── MngService (gelecekte)
  ├── UpsService (gelecekte)
  └── DhlService (gelecekte)
```

**Avantajlar:**
- Her kargo firmasının kendi API'si bağımsız implement edilir
- Yeni kargo firmasi eklemek kolay (tek class oluştur)
- Test edilebilir (mock implementation)
- Kod tekrarı minimumda

### 2. Factory Pattern

`CargoServiceFactory` doğru adapter'ı instantiate eder:

```ruby
service = CargoServiceFactory.create('ptt', shipment)
service.track_shipment
```

## Database Schema

### `shipments` tablosu

```ruby
create_table :shipments do |t|
  t.references :order, null: false, foreign_key: true
  t.string :tracking_number, null: false, index: { unique: true }
  t.string :carrier, null: false, index: true
  t.integer :status, null: false, default: 0, index: true
  t.datetime :shipped_at
  t.datetime :delivered_at
  t.datetime :estimated_delivery
  t.text :notes
  t.timestamps
end
```

**Enum Status:**
```ruby
enum status: {
  preparing: 0,         # Hazırlanıyor
  in_transit: 1,        # Yolda
  out_for_delivery: 2,  # Dağıtımda
  delivered: 3,         # Teslim Edildi
  failed: 4,            # Teslim Edilemedi
  returned: 5           # İade
}
```

## API Endpoints

### 1. List Shipments

```http
GET /api/shipment
Authorization: Bearer {token}
```

**Query Parameters:**
- `carrier` - Kargo firması filtresi (ptt, aras, yurtici, vb.)
- `status` - Durum filtresi (preparing, in_transit, vb.)
- `page` - Sayfa numarası (default: 1)

**Response:**
```json
{
  "data": [
    {
      "id": "1",
      "type": "shipment",
      "attributes": {
        "tracking_number": "PTT123456789",
        "carrier": "ptt",
        "carrier_name": "PTT Kargo",
        "status": "in_transit",
        "status_display": "Yolda",
        "shipped_at": "2025-01-11T12:30:00Z",
        "delivered_at": null,
        "estimated_delivery": "2025-01-14T17:00:00Z",
        "tracking_url": "https://gonderitakip.ptt.gov.tr/Track/Verify?q=PTT123456789",
        "notes": "Express delivery"
      },
      "relationships": {
        "order": {
          "data": {"id": "42", "type": "order"}
        }
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 96
  }
}
```

### 2. Get Shipment Details

```http
GET /api/shipment/:id
Authorization: Bearer {token}
```

**Response:**
```json
{
  "data": {
    "id": "1",
    "type": "shipment",
    "attributes": {
      "tracking_number": "PTT123456789",
      "carrier": "ptt",
      "carrier_name": "PTT Kargo",
      "status": "delivered",
      "status_display": "Teslim Edildi",
      "shipped_at": "2025-01-11T12:30:00Z",
      "delivered_at": "2025-01-13T15:45:00Z",
      "estimated_delivery": "2025-01-14T17:00:00Z",
      "tracking_url": "https://gonderitakip.ptt.gov.tr/Track/Verify?q=PTT123456789",
      "notes": "Express delivery",
      "is_delayed": false,
      "estimated_days": 3
    },
    "relationships": {
      "order": {
        "data": {"id": "42", "type": "order"}
      }
    }
  }
}
```

### 3. Create Shipment (Admin Only)

```http
POST /api/shipment/create
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "order_id": 42,
  "carrier": "ptt",
  "notes": "Fragile - Handle with care"
}
```

**Validations:**
- Order must be in `paid` status
- Order must not have existing shipment
- Carrier must be valid

**Response:**
```json
{
  "message": "Kargo kaydı başarıyla oluşturuldu",
  "data": {
    "id": "1",
    "type": "shipment",
    "attributes": {
      "tracking_number": "PTT123456789",
      "carrier": "ptt",
      "carrier_name": "PTT Kargo",
      "status": "preparing",
      "status_display": "Hazırlanıyor",
      "estimated_delivery": "2025-01-14T17:00:00Z",
      "tracking_url": "https://gonderitakip.ptt.gov.tr/Track/Verify?q=PTT123456789"
    }
  }
}
```

### 4. Update Shipment Status (Admin Only)

```http
PATCH /api/shipment/:id/update_status
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "status": "in_transit",
  "admin_note": "Kargo transfer merkezinde"
}
```

**Valid Status Transitions:**
- `preparing` → `in_transit`, `failed`, `returned`
- `in_transit` → `out_for_delivery`, `failed`, `returned`
- `out_for_delivery` → `delivered`, `failed`, `returned`
- `delivered` → (final state)

**Response:**
```json
{
  "message": "Kargo durumu güncellendi",
  "data": {
    "id": "1",
    "type": "shipment",
    "attributes": {
      "status": "in_transit",
      "status_display": "Yolda",
      "shipped_at": "2025-01-11T12:30:00Z"
    }
  }
}
```

### 5. Track Shipment (Real-time)

```http
GET /api/shipment/:id/track
Authorization: Bearer {token}
```

Bu endpoint kargo firmasının gerçek API'sine bağlanarak canlı takip bilgisi getirir.

**Response:**
```json
{
  "data": {
    "tracking_number": "PTT123456789",
    "carrier": "ptt",
    "current_status": "in_transit",
    "tracking": {
      "status": "in_transit",
      "location": "İstanbul Transfer Merkezi",
      "last_updated": "2025-01-12T08:30:00Z",
      "history": [
        {
          "status": "preparing",
          "location": "Kargo Merkezi - Gönderici",
          "timestamp": "2025-01-11T12:00:00Z",
          "description": "Gönderi hazırlandı"
        },
        {
          "status": "in_transit",
          "location": "Ankara - İstanbul Güzergahı",
          "timestamp": "2025-01-11T18:30:00Z",
          "description": "Kargo yolda"
        },
        {
          "status": "in_transit",
          "location": "İstanbul Transfer Merkezi",
          "timestamp": "2025-01-12T08:30:00Z",
          "description": "Transfer merkezinde"
        }
      ]
    }
  }
}
```

### 6. Cancel Shipment (Admin Only)

```http
POST /api/shipment/:id/cancel
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "reason": "Customer requested cancellation"
}
```

**Response:**
```json
{
  "message": "Kargo iptali başarılı"
}
```

## Supported Carriers

### Aktif Carriers (Mock)

| Carrier | Code | Tracking URL Pattern |
|---------|------|---------------------|
| PTT Kargo | `ptt` | `https://gonderitakip.ptt.gov.tr/Track/Verify?q={tracking}` |
| Aras Kargo | `aras` | `https://kargotakip.araskargo.com.tr/mainpage.aspx?code={tracking}` |
| Yurtiçi Kargo | `yurtici` | `https://www.yurticikargo.com/tr/online-servisler/gonderi-sorgula?code={tracking}` |

### Planlanan Carriers

| Carrier | Code | Tracking URL Pattern |
|---------|------|---------------------|
| MNG Kargo | `mng` | `https://www.mngkargo.com.tr/takip?q={tracking}` |
| UPS | `ups` | `https://www.ups.com/track?tracknum={tracking}` |
| DHL | `dhl` | `https://www.dhl.com/tr-tr/home/tracking.html?tracking-id={tracking}` |

## Service Adapter Implementation

### Base Service

```ruby
# app/services/cargo/base_service.rb
class Cargo::BaseService
  def initialize(shipment)
    @shipment = shipment
  end

  # Abstract methods - her adapter override etmeli
  def create_shipment
    raise NotImplementedError
  end

  def track_shipment
    raise NotImplementedError
  end

  def cancel_shipment
    raise NotImplementedError
  end

  protected

  # Helper methods tüm adapter'larda kullanılabilir
  def prepare_order_data; end
  def generate_mock_tracking_number; end
  def calculate_estimated_delivery(days); end
end
```

### Example: PTT Service

```ruby
# app/services/cargo/ptt_service.rb
class Cargo::PttService < Cargo::BaseService
  # Mock implementation
  def create_shipment
    tracking_number = generate_mock_tracking_number('PTT')
    
    # TODO: Gerçek PTT API'ye bağlan
    # result = create_via_api
    
    {
      tracking_number: tracking_number,
      estimated_delivery: calculate_estimated_delivery(3)
    }
  end

  def track_shipment
    # TODO: Gerçek PTT API'den takip bilgisi çek
    {
      status: 'in_transit',
      location: 'İstanbul Transfer Merkezi',
      last_updated: Time.current,
      history: [...]
    }
  end

  def cancel_shipment
    # TODO: PTT API'ye iptal isteği gönder
    true
  end

  private

  def create_via_api
    # PTT API credentials
    # api_url = 'https://ptt.gov.tr/api/v1/shipments'
    # response = HTTP.post(api_url, json: payload)
    # response.parse
  end
end
```

## Yeni Kargo Firması Ekleme

### Adım 1: Service Class Oluştur

```ruby
# app/services/cargo/mng_service.rb
class Cargo::MngService < Cargo::BaseService
  def create_shipment
    # MNG API ile kargo oluştur
    {
      tracking_number: api_response['trackingNo'],
      estimated_delivery: calculate_estimated_delivery(2)
    }
  end

  def track_shipment
    # MNG API'den tracking bilgisi
    api_response = fetch_from_mng_api
    parse_tracking_response(api_response)
  end

  def cancel_shipment
    # MNG'ye iptal isteği
    cancel_via_mng_api
  end

  private

  def fetch_from_mng_api
    # API implementation
  end
end
```

### Adım 2: CARRIERS Hash'e Ekle

```ruby
# app/models/shipment.rb
CARRIERS = {
  'ptt' => 'PTT Kargo',
  'aras' => 'Aras Kargo',
  'yurtici' => 'Yurtiçi Kargo',
  'mng' => 'MNG Kargo'  # Yeni eklenen
}.freeze
```

### Adım 3: Factory'de Register Et

```ruby
# app/services/cargo/service_factory.rb
def self.create(carrier, shipment)
  case carrier
  when 'ptt' then Cargo::PttService.new(shipment)
  when 'aras' then Cargo::ArasService.new(shipment)
  when 'yurtici' then Cargo::YurticiService.new(shipment)
  when 'mng' then Cargo::MngService.new(shipment)  # Yeni eklenen
  else
    raise ArgumentError, "Unsupported carrier: #{carrier}"
  end
end
```

## Real API Integration Guide

### PTT Kargo Integration

```ruby
# Gemfile
gem 'httparty' # or 'faraday'

# config/initializers/ptt_cargo.rb
PTT_CONFIG = {
  api_url: ENV['PTT_API_URL'],
  username: ENV['PTT_USERNAME'],
  password: ENV['PTT_PASSWORD'],
  customer_code: ENV['PTT_CUSTOMER_CODE']
}

# app/services/cargo/ptt_service.rb
def create_via_api
  response = HTTParty.post(
    "#{PTT_CONFIG[:api_url]}/shipment/create",
    body: {
      customerCode: PTT_CONFIG[:customer_code],
      sender: prepare_sender_data,
      receiver: prepare_receiver_data,
      parcel: prepare_parcel_data
    }.to_json,
    headers: {
      'Content-Type' => 'application/json',
      'Authorization' => "Basic #{auth_token}"
    }
  )
  
  response.parsed_response
end

def auth_token
  Base64.strict_encode64("#{PTT_CONFIG[:username]}:#{PTT_CONFIG[:password]}")
end
```

### Aras Kargo Integration (SOAP)

```ruby
# Gemfile
gem 'savon'

# app/services/cargo/aras_service.rb
def soap_client
  @soap_client ||= Savon.client(
    wsdl: ENV['ARAS_WSDL_URL'],
    namespace: 'http://tempuri.org/',
    convert_request_keys_to: :none
  )
end

def create_via_api
  response = soap_client.call(
    :create_shipping,
    message: {
      UserName: ENV['ARAS_USERNAME'],
      Password: ENV['ARAS_PASSWORD'],
      Sender: prepare_sender_xml,
      Receiver: prepare_receiver_xml
    }
  )
  
  response.body[:create_shipping_response]
end
```

### Yurtiçi Kargo Integration (REST)

```ruby
# app/services/cargo/yurtici_service.rb
def create_via_api
  response = HTTParty.post(
    "#{ENV['YURTICI_API_URL']}/createShipment",
    body: {
      senderCity: @shipment.order.billing_city,
      receiverName: @shipment.order.shipping_name,
      # ... diğer alanlar
    }.to_json,
    headers: {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['YURTICI_API_TOKEN']}"
    }
  )
  
  response.parsed_response
end
```

## Model Callbacks

Shipment modelinde otomatik işlemler:

```ruby
# app/models/shipment.rb
after_create :notify_customer
after_update :sync_order_status

# Status değişince order'ı da güncelle
def sync_order_status
  if delivered? && order.status != 'completed'
    order.update(status: 'completed')
  end
end

# Kargo oluşunca müşteriye email
def notify_customer
  NotificationMailer.shipment_created(self).deliver_later
end
```

## Authorization

- **List/Show/Track**: Hem admin hem de sipariş sahibi kullanıcı erişebilir
- **Create/Update/Cancel**: Sadece admin erişebilir

```ruby
# app/controllers/api/shipment_controller.rb
before_action :require_admin_for_create!, only: [:create]
before_action :require_admin!, only: [:update_status, :cancel]
before_action :require_admin_or_owner!, only: [:show, :track]
```

## Testing

### RSpec Example

```ruby
# spec/services/cargo/ptt_service_spec.rb
RSpec.describe Cargo::PttService do
  let(:order) { create(:order, :paid) }
  let(:shipment) { create(:shipment, order: order, carrier: 'ptt') }
  let(:service) { described_class.new(shipment) }

  describe '#create_shipment' do
    it 'generates tracking number' do
      result = service.create_shipment
      expect(result[:tracking_number]).to start_with('PTT')
    end

    it 'calculates estimated delivery' do
      result = service.create_shipment
      expect(result[:estimated_delivery]).to be > Time.current
    end
  end

  describe '#track_shipment' do
    it 'returns tracking history' do
      result = service.track_shipment
      expect(result).to have_key(:history)
      expect(result[:history]).to be_an(Array)
    end
  end
end
```

### Integration Test

```ruby
# spec/requests/shipment_spec.rb
RSpec.describe 'Shipment API' do
  let(:admin) { create(:user, :admin) }
  let(:admin_token) { generate_jwt(admin) }

  describe 'POST /api/shipment/create' do
    let(:order) { create(:order, :paid) }
    
    it 'creates shipment successfully' do
      post '/api/shipment/create',
        params: { order_id: order.id, carrier: 'ptt' },
        headers: { 'Authorization' => "Bearer #{admin_token}" }

      expect(response).to have_http_status(:created)
      expect(json_response['data']['attributes']).to have_key('tracking_number')
    end
  end
end
```

## Environment Variables

```bash
# .env
PTT_API_URL=https://ptt.gov.tr/api/v1
PTT_USERNAME=your_username
PTT_PASSWORD=your_password
PTT_CUSTOMER_CODE=12345

ARAS_WSDL_URL=https://api.araskargo.com.tr/services?wsdl
ARAS_USERNAME=your_username
ARAS_PASSWORD=your_password

YURTICI_API_URL=https://api.yurticikargo.com/v1
YURTICI_API_TOKEN=your_bearer_token
```

## Error Handling

```ruby
# app/controllers/api/shipment_controller.rb
def create
  # ... shipment creation logic
  
  service = CargoServiceFactory.create(params[:carrier], shipment)
  result = service.create_shipment
  
rescue ArgumentError => e
  render json: { error: e.message }, status: :unprocessable_entity
rescue StandardError => e
  Rails.logger.error "Shipment creation failed: #{e.message}"
  render json: { error: 'Kargo oluşturulurken hata oluştu' }, status: :internal_server_error
end
```

## Webhook Support (Gelecek)

Kargo firmalarından otomatik durum güncellemeleri almak için:

```ruby
# config/routes.rb
namespace :webhooks do
  post 'ptt/status_update', to: 'cargo#ptt_update'
  post 'aras/status_update', to: 'cargo#aras_update'
end

# app/controllers/webhooks/cargo_controller.rb
class Webhooks::CargoController < ApplicationController
  skip_before_action :verify_authenticity_token
  
  def ptt_update
    # PTT'den gelen webhook'u işle
    shipment = Shipment.find_by(tracking_number: params[:tracking_number])
    shipment.update(status: map_ptt_status(params[:status]))
    
    head :ok
  end
end
```

## Performance Optimization

### Caching Tracking Results

```ruby
# app/services/cargo/base_service.rb
def track_shipment
  Rails.cache.fetch("shipment_tracking_#{@shipment.id}", expires_in: 5.minutes) do
    fetch_tracking_from_api
  end
end
```

### Background Jobs for Status Updates

```ruby
# app/jobs/update_shipment_status_job.rb
class UpdateShipmentStatusJob < ApplicationJob
  def perform(shipment_id)
    shipment = Shipment.find(shipment_id)
    service = CargoServiceFactory.create(shipment.carrier, shipment)
    tracking_data = service.track_shipment
    
    shipment.update(status: tracking_data[:status]) if tracking_data[:status]
  end
end

# Scheduled job (sidekiq-scheduler)
UpdateShipmentStatusJob.perform_later(shipment.id)
```

## Monitoring & Logging

```ruby
# app/services/cargo/base_service.rb
def track_shipment
  start_time = Time.current
  result = fetch_tracking_from_api
  duration = Time.current - start_time
  
  Rails.logger.info(
    "Cargo API Call",
    carrier: @shipment.carrier,
    tracking_number: @shipment.tracking_number,
    duration: duration,
    status: result[:status]
  )
  
  result
end
```

## Admin Notes

Admin'ler her shipment'a not ekleyebilir:

```ruby
# Polymorphic association
@shipment.admin_notes.create(
  user: current_user,
  note: "Müşteri adresi değiştirildi"
)
```

## Best Practices

1. **Mock First, Real Later**: İlk geliştirmede mock ile başla, API credentials hazır olunca real integration yap
2. **Error Handling**: Her API call'u try-catch ile koru
3. **Logging**: Her API call'u logla (debugging için kritik)
4. **Caching**: Tracking sonuçlarını 5-10 dakika cache'le
5. **Background Jobs**: Status update'leri async yap
6. **Webhooks**: Mümkünse push-based updates kullan (polling yerine)
7. **Rate Limiting**: API rate limit'lerini respecte et
8. **Idempotency**: Duplicate shipment oluşumunu engelle (order başına tek shipment)

## Troubleshooting

### Problem: Shipment created but no tracking number
**Çözüm**: Kargo API'si yanıt vermemiş olabilir. Service adapter'daki error handling'i kontrol et.

### Problem: Status not updating
**Çözüm**: Webhook'lar çalışmıyor olabilir. Background job'ları kontrol et veya manuel polling ekle.

### Problem: Wrong tracking URL
**Çözüm**: `tracking_url` metodunu kontrol et, carrier mapping'i doğru mu?

## Future Enhancements

- [ ] Webhook support for automatic status updates
- [ ] SMS notifications for delivery status
- [ ] QR code generation for tracking
- [ ] Bulk shipment creation
- [ ] Return/exchange shipment support
- [ ] International shipping support
- [ ] Shipping label PDF generation
- [ ] Real-time delivery map tracking
