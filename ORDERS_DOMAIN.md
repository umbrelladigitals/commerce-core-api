# 🛒 Orders Domain - Sipariş Yönetim Sistemi

## 📋 Genel Bakış

Orders domain'i, e-ticaret platformunun sipariş ve sepet yönetim sistemini içerir. Kullanıcılar sepete ürün ekleyebilir, ödeme yapabilir ve siparişlerini takip edebilir.

## 🏗️ Veritabanı Yapısı

### Orders Tablosu
```ruby
create_table :orders do |t|
  t.references :user, null: false, foreign_key: true
  t.integer :status, default: 0                    # Sipariş durumu (enum)
  t.integer :subtotal_cents, default: 0            # Ara toplam (vergi ve kargo hariç)
  t.integer :shipping_cents, default: 0            # Kargo ücreti
  t.integer :tax_cents, default: 0                 # KDV (%18)
  t.integer :total_cents                           # Genel toplam
  t.string :currency, default: 'USD'               # Para birimi
  t.datetime :paid_at                              # Ödeme tarihi
  t.datetime :shipped_at                           # Kargoya verilme tarihi
  t.datetime :cancelled_at                         # İptal tarihi
  t.timestamps
end
```

### OrderLines Tablosu
```ruby
create_table :order_lines do |t|
  t.references :order, null: false, foreign_key: true
  t.references :product, null: false, foreign_key: true
  t.references :variant, null: true, foreign_key: true
  t.integer :quantity, null: false, default: 1     # Ürün adedi
  t.integer :unit_price_cents, null: false         # Birim fiyat
  t.integer :total_cents, null: false              # Toplam (quantity * unit_price)
  t.text :note                                     # Özel not
  t.timestamps
end

add_index :order_lines, [:order_id, :product_id, :variant_id]
```

## 🎯 Sipariş Durumları (Status Enum)

```ruby
enum status: {
  cart: 0,      # Sepet - Henüz ödeme yapılmamış
  paid: 1,      # Ödendi - Ödeme alındı, işleme hazır
  shipped: 2,   # Kargoda - Kargoya verildi
  cancelled: 3  # İptal - İptal edildi
}
```

### Durum Geçişleri

```
cart ──────► paid ──────► shipped
  │            │
  └────────────┴──────► cancelled
```

## 📦 Modeller

### Order Model

**İlişkiler:**
```ruby
belongs_to :user
has_many :order_lines, dependent: :destroy
has_many :products, through: :order_lines
```

**Para Birimleri (Money-Rails):**
```ruby
monetize :total_cents, as: :total
monetize :subtotal_cents, as: :subtotal
monetize :tax_cents, as: :tax
monetize :shipping_cents, as: :shipping
```

**Önemli Metodlar:**
- `order_number` - Sipariş numarası (örn: ORD-20231010-000001)
- `total_items` - Toplam ürün sayısı
- `payable?` - Sipariş ödenebilir mi? (sepet dolu ve stok var mı)
- `all_items_in_stock?` - Tüm ürünler stokta mı?
- `mark_as_paid!` - Siparişi ödenmiş olarak işaretle
- `mark_as_shipped!` - Siparişi kargoya verilmiş olarak işaretle
- `cancel!` - Siparişi iptal et ve stokları geri yükle
- `restore_stock!` - Stokları geri yükle

**Scope'lar:**
```ruby
scope :active_carts        # Son 24 saatteki aktif sepetler
scope :completed           # Tamamlanmış siparişler (paid, shipped)
scope :pending_shipment    # Kargoya verilmeyi bekleyen siparişler
```

### OrderLine Model

**İlişkiler:**
```ruby
belongs_to :order
belongs_to :product, class_name: 'Catalog::Product'
belongs_to :variant, class_name: 'Catalog::Variant', optional: true
```

**Önemli Metodlar:**
- `item_name` - Ürün adı (variant varsa onunla birlikte)
- `check_stock` - Stok kontrolü
- `reserve_stock!` - Stoktan düş (sepet → ödeme geçişinde)

**Otomatik Hesaplamalar:**
- `set_prices` - Variant veya Product fiyatını otomatik ayarla
- `calculate_total` - total_cents = unit_price_cents * quantity
- `update_order_totals` - OrderPriceCalculator ile siparişi güncelle

## 💰 OrderPriceCalculator Servisi

Sipariş fiyat hesaplama servisi. Ara toplam, kargo, vergi ve genel toplamı hesaplar.

### Kullanım

```ruby
calculator = Orders::OrderPriceCalculator.new(order)
calculator.calculate!  # Hesapla ve kaydet
```

### Hesaplama Mantığı

1. **Ara Toplam (Subtotal):**
   ```ruby
   subtotal = order_lines.sum(:total_cents)
   ```

2. **Kargo Ücreti (Shipping):**
   - 200 TL ve üzeri: **ÜCRETSİZ** 🎉
   - 200 TL altı: **30 TL**
   ```ruby
   FREE_SHIPPING_THRESHOLD = 20000  # 200.00 TL
   SHIPPING_FEE = 3000              # 30.00 TL
   ```

3. **KDV (%18):**
   ```ruby
   tax = (subtotal + shipping) * 0.18
   ```

4. **Genel Toplam:**
   ```ruby
   total = subtotal + shipping + tax
   ```

### Preview (Önizleme)

Kaydetmeden önizleme için:

```ruby
calculator.preview
# => {
#   subtotal_cents: 100000,
#   subtotal: "$1,000.00",
#   shipping_cents: 0,
#   shipping: "$0.00",
#   tax_cents: 18000,
#   tax: "$180.00",
#   total_cents: 118000,
#   total: "$1,180.00",
#   currency: "USD",
#   items_count: 3,
#   free_shipping: true
# }
```

## 🛒 Cart API Endpoints

### 1. Sepeti Göster

```bash
GET /api/cart
Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "data": {
    "type": "cart",
    "id": "1",
    "attributes": {
      "status": "cart",
      "items_count": 2,
      "total_quantity": 3,
      "subtotal": "$2,699.98",
      "shipping": "$30.00",
      "tax": "$491.40",
      "total": "$3,221.38",
      "currency": "USD",
      "free_shipping": false,
      "payable": true
    },
    "relationships": {
      "items": {
        "data": [
          { "type": "order_lines", "id": "1" },
          { "type": "order_lines", "id": "2" }
        ]
      }
    },
    "included": [
      {
        "type": "order_lines",
        "id": "1",
        "attributes": {
          "product_id": 1,
          "product_title": "MacBook Pro 16\"",
          "variant_id": 1,
          "variant_name": "storage: 512GB, color: Silver",
          "quantity": 1,
          "unit_price": "$2,499.99",
          "total": "$2,499.99",
          "note": null
        }
      }
    ]
  }
}
```

### 2. Sepete Ürün Ekle

```bash
POST /api/cart/add
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

{
  "product_id": 1,
  "variant_id": 1,      // Opsiyonel
  "quantity": 1,
  "note": "Hediye paketi"  // Opsiyonel
}
```

**Response:**
```json
{
  "message": "Ürün sepete eklendi",
  "data": {
    "type": "order_lines",
    "id": "1",
    "attributes": {
      "product_id": 1,
      "product_title": "MacBook Pro 16\"",
      "variant_id": 1,
      "variant_name": "storage: 512GB, color: Silver",
      "quantity": 1,
      "unit_price": "$2,499.99",
      "total": "$2,499.99",
      "note": "Hediye paketi"
    }
  },
  "meta": {
    "cart_total_items": 1,
    "cart_total": "$2,499.99"
  }
}
```

**Hata Durumları:**
- Stok yetersiz: `422 Unprocessable Entity`
- Ürün bulunamadı: `404 Not Found`
- Variant ürüne ait değil: `422 Unprocessable Entity`

### 3. Ürün Miktarını Güncelle

```bash
PATCH /api/cart/items/{id}
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

{
  "quantity": 3
}
```

### 4. Sepetten Ürün Çıkar

```bash
DELETE /api/cart/items/{id}
Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "message": "Ürün sepetten çıkarıldı",
  "meta": {
    "cart_total_items": 1,
    "cart_total": "$199.98"
  }
}
```

### 5. Sepeti Temizle

```bash
DELETE /api/cart/clear
Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "message": "Sepet temizlendi"
}
```

### 6. Ödemeye Geç (Checkout)

```bash
POST /api/cart/checkout
Authorization: Bearer {JWT_TOKEN}
```

**Response:**
```json
{
  "message": "Ödeme işlemi başlatıldı",
  "data": {
    "type": "checkout",
    "attributes": {
      "order_id": 1,
      "order_number": "ORD-20231010-000001",
      "total": "$3,221.38",
      "currency": "USD"
    }
  },
  "meta": {
    "next_step": "POST /api/payment/confirm ile ödemeyi onaylayın"
  }
}
```

**Hata Durumları:**
- Sepet boş: `422 Unprocessable Entity`
- Stok yetersiz: `422 Unprocessable Entity`

## 💳 Payment API Endpoints

### 1. Ödemeyi Onayla (Test/Manuel)

```bash
POST /api/payment/confirm
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json

{
  "order_id": 1
}
```

**Response:**
```json
{
  "message": "Ödeme onaylandı",
  "data": {
    "type": "orders",
    "id": "1",
    "attributes": {
      "order_number": "ORD-20231010-000001",
      "status": "paid",
      "total": "$3,221.38",
      "paid_at": "2023-10-10T15:30:00.000Z",
      "created_at": "2023-10-10T15:25:00.000Z"
    }
  },
  "meta": {
    "confirmation_email_sent": true
  }
}
```

**Arka Planda:**
- Sipariş durumu `cart` → `paid` olur
- `OrderConfirmationJob` tetiklenir (mail gönderimi)
- Log'a sipariş detayları yazılır

### 2. Webhook (Stripe Entegrasyonu)

```bash
POST /api/payment/webhook
Content-Type: application/json
Stripe-Signature: {signature}

{
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_xxx",
      "metadata": {
        "order_id": "1"
      }
    }
  }
}
```

**Desteklenen Event'ler:**
- `payment_intent.succeeded` - Ödeme başarılı
- `payment_intent.payment_failed` - Ödeme başarısız
- `charge.refunded` - İade işlemi

**Ödeme Başarılı:**
1. Order durumu `paid` olarak işaretlenir
2. `OrderConfirmationJob` tetiklenir
3. Log'a kaydedilir

**Ödeme Başarısız:**
1. Stoklar geri yüklenir (`restore_stock!`)
2. Log'a uyarı yazılır
3. Kullanıcıya bildirim gönderilebilir (opsiyonel)

## 📧 OrderConfirmationJob (Sidekiq)

Sipariş onay maili gönderen arka plan job'ı.

### Tetiklenme Zamanları

- Ödeme başarılı olduğunda (`POST /api/payment/confirm`)
- Stripe webhook'u geldiğinde (`payment_intent.succeeded`)

### Kullanım

```ruby
Orders::OrderConfirmationJob.perform_later(order_id)
```

### İşlevler

1. **Mail Gönderimi:**
   ```ruby
   # Gerçek uygulamada:
   OrderMailer.confirmation(order).deliver_now
   
   # Şu an: Log'a yazar
   Rails.logger.info "📧 SIPARIŞ ONAYI - #{order.order_number}"
   ```

2. **Bildirimler:**
   - SMS bildirimi (opsiyonel)
   - Push notification (opsiyonel)

3. **Analytics:**
   - Google Analytics event tracking
   - Internal analytics kayıt

### Retry Stratejisi

```ruby
retry_on StandardError, wait: 5.seconds, attempts: 3
```

Hata durumunda 5 saniye bekleyip 3 kez tekrar dener.

### Log Formatı

```
📧 SIPARIŞ ONAYI
================
Sipariş No: ORD-20231010-000001
Müşteri: John Customer (customer@example.com)
Toplam: $3,221.38
Ürün Sayısı: 3

Sipariş Detayları:
  - MacBook Pro 16" - storage: 512GB, color: Silver x1 = $2,499.99
  - Logitech MX Master 3 x2 = $199.98

Ara Toplam: $2,699.97
Kargo: $30.00
KDV (%18): $491.39
Genel Toplam: $3,221.36
================
```

## 🧪 Test Senaryoları

### 1. Sepete Ürün Ekleme

```bash
# Login
curl -X POST http://localhost:3000/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "customer@example.com",
      "password": "password123"
    }
  }'

# Token'ı al (response header'dan)
TOKEN="eyJhbGciOiJIUzI1NiJ9..."

# Sepete ürün ekle
curl -X POST http://localhost:3000/api/cart/add \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "variant_id": 1,
    "quantity": 1
  }'
```

### 2. Sepeti Görüntüleme

```bash
curl -X GET http://localhost:3000/api/cart \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Checkout ve Ödeme

```bash
# Checkout
curl -X POST http://localhost:3000/api/cart/checkout \
  -H "Authorization: Bearer $TOKEN"

# Ödemeyi onayla (order_id response'dan al)
curl -X POST http://localhost:3000/api/payment/confirm \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order_id": 2
  }'
```

### 4. Sidekiq Job Kontrolü

```bash
# Rails console
rails console

# Job'ı manuel tetikle
order = Orders::Order.last
Orders::OrderConfirmationJob.perform_now(order.id)

# Sidekiq queue kontrol
Sidekiq::Stats.new.default_size
```

## 📊 Seed Verileri

Seeds dosyası 2 örnek sipariş oluşturur:

### 1. Aktif Sepet (Customer)
- **Durum:** cart
- **Ürünler:**
  - MacBook Pro 16" (Silver, 512GB) x1
  - Logitech MX Master 3 x2
- **Toplam:** ~$3,200

### 2. Ödenmiş Sipariş (Dealer)
- **Durum:** paid
- **Ödeme Tarihi:** 2 gün önce
- **Ürünler:**
  - Keychron K2 (Red switch) x3
  - Sony WH-1000XM5 x1
- **Toplam:** ~$670

## 🚀 Sıradaki Adımlar

### Stripe Entegrasyonu

1. **Stripe gem ekle:**
   ```ruby
   gem 'stripe'
   ```

2. **Credentials'a API key ekle:**
   ```bash
   EDITOR="vim" rails credentials:edit
   ```
   ```yaml
   stripe:
     secret_key: sk_test_xxx
     publishable_key: pk_test_xxx
     webhook_secret: whsec_xxx
   ```

3. **PaymentIntent oluştur:**
   ```ruby
   Stripe::PaymentIntent.create(
     amount: order.total_cents,
     currency: order.currency.downcase,
     metadata: { order_id: order.id }
   )
   ```

### Email Gönderimi

1. **Action Mailer oluştur:**
   ```bash
   rails g mailer OrderMailer confirmation
   ```

2. **Job'dan çağır:**
   ```ruby
   OrderMailer.confirmation(order).deliver_now
   ```

### İstatistikler

- Günlük sipariş sayısı
- Ortalama sepet değeri
- En çok satan ürünler
- Terk edilmiş sepetler (cart > 24 saat)

---

**Hazırlayan:** Commerce Core API
**Tarih:** Ekim 2023
**Versiyon:** 1.0
