# Shipment System - Quick Start Guide

## 🚀 Hızlı Başlangıç

Kargo takip sistemini 5 dakikada test edin!

### 1. Database Migrate

```bash
cd /home/umbrella/b2bruby/commerce_core_api
rails db:migrate
```

### 2. Rails Server Başlat

```bash
rails s
```

### 3. Test Script Çalıştır

Yeni terminal'de:

```bash
./test_shipment_api.sh
```

## 📦 Ne Yapar?

Test script otomatik olarak:
1. ✅ Admin login yapar
2. ✅ Test siparişi oluşturur
3. ✅ 3 farklı kargo ile shipment oluşturur (PTT, Aras, Yurtiçi)
4. ✅ Tracking number'ları generate eder
5. ✅ Status update'leri test eder
6. ✅ Real-time tracking'i simüle eder
7. ✅ Delivery confirmation yapar

## 🎯 Key Endpoints

### Create Shipment (Admin)
```bash
POST /api/shipment/create
{
  "order_id": 1,
  "carrier": "ptt",
  "notes": "Express delivery"
}
```

### Track Shipment
```bash
GET /api/shipment/1/track
```

### Update Status (Admin)
```bash
PATCH /api/shipment/1/update_status
{
  "status": "in_transit",
  "admin_note": "Kargo yolda"
}
```

## 🏭 Supported Carriers

| Carrier | Code | Mock Ready | Real API |
|---------|------|------------|----------|
| PTT Kargo | `ptt` | ✅ | ⏳ |
| Aras Kargo | `aras` | ✅ | ⏳ |
| Yurtiçi Kargo | `yurtici` | ✅ | ⏳ |
| MNG Kargo | `mng` | ⏳ | ⏳ |
| UPS | `ups` | ⏳ | ⏳ |
| DHL | `dhl` | ⏳ | ⏳ |

## 🔍 Manual Testing

### 1. Admin Token Al

```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@test.com",
      "password": "password123"
    }
  }'
```

**Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {...}
}
```

### 2. Shipment Oluştur

```bash
curl -X POST http://localhost:3000/api/shipment/create \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": 1,
    "carrier": "ptt"
  }'
```

**Response:**
```json
{
  "message": "Kargo kaydı başarıyla oluşturuldu",
  "data": {
    "id": "1",
    "attributes": {
      "tracking_number": "PTT123456789",
      "carrier": "ptt",
      "carrier_name": "PTT Kargo",
      "status": "preparing",
      "tracking_url": "https://gonderitakip.ptt.gov.tr/Track/Verify?q=PTT123456789"
    }
  }
}
```

### 3. Tracking Yap

```bash
curl -X GET http://localhost:3000/api/shipment/1/track \
  -H "Authorization: Bearer YOUR_TOKEN"
```

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
      "history": [...]
    }
  }
}
```

### 4. Status Güncelle

```bash
curl -X PATCH http://localhost:3000/api/shipment/1/update_status \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "delivered",
    "admin_note": "Teslim edildi"
  }'
```

## 📊 Status Flow

```
preparing → in_transit → out_for_delivery → delivered
              ↓              ↓                  
            failed       failed
              ↓              ↓
           returned     returned
```

## 🛠️ Architecture

```
ShipmentController
    ↓
CargoServiceFactory
    ↓
├── PttService (Mock)
├── ArasService (Mock)
└── YurticiService (Mock)
```

## 📁 Files Created

```
app/
  models/shipment.rb                           ← Model
  controllers/api/shipment_controller.rb       ← API Controller
  services/cargo/
    base_service.rb                            ← Base Adapter
    ptt_service.rb                             ← PTT Implementation
    aras_service.rb                            ← Aras Implementation
    yurtici_service.rb                         ← Yurtiçi Implementation
    service_factory.rb                         ← Factory Pattern

db/migrate/20251011235955_create_shipments.rb  ← Migration

test_shipment_api.sh                           ← Test Script
SHIPMENT_API.md                                ← Full Documentation
```

## 🔐 Authorization

- **List, Show, Track**: Admin veya sipariş sahibi
- **Create, Update, Cancel**: Sadece admin

## 🧪 Testing Checklist

- [x] Create shipment with PTT
- [x] Create shipment with Aras
- [x] Create shipment with Yurtiçi
- [x] Track shipment (mock)
- [x] Update status to in_transit
- [x] Update status to delivered
- [x] List all shipments
- [x] Filter by carrier
- [x] Filter by status
- [x] Authorization (admin vs user)

## 🎨 Example Response (JSON:API Format)

```json
{
  "data": {
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

## 🚦 Status Meanings

| Status | Turkish | Description |
|--------|---------|-------------|
| `preparing` | Hazırlanıyor | Kargo hazırlanıyor |
| `in_transit` | Yolda | Transfer merkezlerinde |
| `out_for_delivery` | Dağıtımda | Kurye dağıtıma çıktı |
| `delivered` | Teslim Edildi | Başarıyla teslim edildi |
| `failed` | Teslim Edilemedi | Teslim başarısız |
| `returned` | İade | Gönderene iade ediliyor |

## 🔗 Tracking URLs

### PTT Kargo
```
https://gonderitakip.ptt.gov.tr/Track/Verify?q={tracking_number}
```

### Aras Kargo
```
https://kargotakip.araskargo.com.tr/mainpage.aspx?code={tracking_number}
```

### Yurtiçi Kargo
```
https://www.yurticikargo.com/tr/online-servisler/gonderi-sorgula?code={tracking_number}
```

## 💡 Tips

### Yeni Kargo Firması Ekle

1. `app/services/cargo/` altına yeni service oluştur:
```ruby
class Cargo::MngService < Cargo::BaseService
  def create_shipment
    # Implementation
  end
end
```

2. `CARRIERS` hash'ine ekle (shipment.rb)
3. Factory'ye ekle (service_factory.rb)

### Real API'ye Geçiş

1. Environment variables ekle:
```bash
PTT_API_URL=...
PTT_USERNAME=...
PTT_PASSWORD=...
```

2. Service'deki `create_via_api` metodunu implement et
3. Mock yerine real call yap

## 📚 Documentation

Detaylı dokümantasyon için:
```bash
cat SHIPMENT_API.md
```

## 🐛 Troubleshooting

### "Order already has a shipment"
→ Her order için sadece 1 shipment olabilir

### "Order must be paid"
→ Sadece ödeme yapılmış siparişlere kargo eklenebilir

### "Unauthorized"
→ Admin token kullandığınızdan emin olun

### Syntax Error
→ Kontrol et:
```bash
ruby -c app/models/shipment.rb
```

## ✅ Success Criteria

Test başarılı ise şunları göreceksiniz:

```
✓ Admin authentication
✓ Shipment creation (PTT, Aras, Yurtiçi)
✓ Tracking number generation (mock)
✓ Status updates
✓ Real-time tracking (mock)
✓ Shipment listing & filtering
✓ Delivery confirmation

All tests completed!
```

## 🎯 Next Steps

1. ✅ Mock implementation (DONE)
2. ⏳ Real PTT API integration
3. ⏳ Real Aras API integration (SOAP)
4. ⏳ Real Yurtiçi API integration
5. ⏳ Webhook support for auto-updates
6. ⏳ SMS notifications
7. ⏳ Email notifications

## 📞 Support

Detaylı API dokümantasyonu: `SHIPMENT_API.md`
Test script: `test_shipment_api.sh`
Migration: `db/migrate/20251011235955_create_shipments.rb`
