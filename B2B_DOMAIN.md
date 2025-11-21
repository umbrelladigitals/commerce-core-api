# 💼 B2B Domain - İşletmeler Arası E-Ticaret

## 📋 Genel Bakış

B2B (Business-to-Business) domain'i, dealer (bayi) kullanıcıları için özel fiyatlandırma, indirimler ve cari hesap yönetimi sağlar. Normal müşterilere göre dealer'lar:

- ✅ Ürünlerde özel indirimler alır
- ✅ Daha düşük ücretsiz kargo limiti (100 TL vs 200 TL)
- ✅ Cari hesap ile borç/alacak takibi
- ✅ Kredi limiti ile esnek ödeme

## 🏗️ Veritabanı Yapısı

### dealer_discounts Tablosu
```ruby
create_table :dealer_discounts do |t|
  t.references :dealer, null: false, foreign_key: { to_table: :users }
  t.references :product, null: false, foreign_key: true
  t.decimal :discount_percent, precision: 5, scale: 2  # Örn: 15.50%
  t.boolean :active, default: true
  t.timestamps
end

add_index :dealer_discounts, [:dealer_id, :product_id], unique: true
```

**Özellikler:**
- Her dealer için her üründe farklı indirim oranı
- İndirim %0-100 arası olabilir
- Aktif/pasif yapılabilir
- Bir dealer + product kombinasyonu benzersiz

### dealer_balances Tablosu
```ruby
create_table :dealer_balances do |t|
  t.references :dealer, null: false, foreign_key: { to_table: :users }
  t.integer :balance_cents, default: 0           # Cari hesap bakiyesi
  t.string :currency, default: 'USD'
  t.integer :credit_limit_cents, default: 0      # Kredi limiti
  t.datetime :last_transaction_at
  t.timestamps
end
```

**Özellikler:**
- Her dealer'ın unique bir bakiyesi
- Pozitif bakiye: Dealer'ın lehine (ön ödeme)
- Negatif bakiye: Dealer'ın borcu
- Kredi limiti: Ne kadar borçlanabilir

## 📦 Modeller

### B2b::DealerDiscount

**İlişkiler:**
```ruby
belongs_to :dealer, class_name: 'User'
belongs_to :product, class_name: 'Catalog::Product'
```

**Validasyonlar:**
- `discount_percent`: 0-100 arası olmalı
- `dealer_id + product_id`: Unique olmalı
- `dealer`: Dealer role'üne sahip olmalı

**Önemli Metodlar:**

```ruby
# İndirimli fiyat hesapla
discount.calculate_discounted_price(100000)  # => 85000 (15% indirimli)

# İndirim tutarı
discount.discount_amount(100000)  # => 15000

# Formatlanmış indirim
discount.formatted_discount  # => "15.0%"

# Aktif/pasif
discount.toggle_active!
```

**Scope'lar:**
```ruby
DealerDiscount.active                    # Aktif indirimler
DealerDiscount.for_dealer(dealer_id)     # Belirli dealer
DealerDiscount.for_product(product_id)   # Belirli ürün
```

### B2b::DealerBalance

**İlişkiler:**
```ruby
belongs_to :dealer, class_name: 'User'
```

**Money-Rails Entegrasyonu:**
```ruby
monetize :balance_cents, as: :balance
monetize :credit_limit_cents, as: :credit_limit
```

**Önemli Metodlar:**

```ruby
# Para ekle (ödeme alındığında)
balance.add_credit!(10000, note: "Fatura #123 ödemesi")  # => true

# Para düş (sipariş verildiğinde)
balance.deduct!(5000, note: "Sipariş #456")  # => true/false

# Kullanılabilir bakiye
balance.available_balance          # => Money($1,500.00)
balance.available_balance_cents    # => 150000

# Bakiye kontrolü
balance.sufficient_balance?(10000)  # => true/false
balance.positive_balance?           # => true/false
balance.negative_balance?           # => true/false (borçlu)
balance.over_limit?                 # => true/false (limit aşımı)

# Borç miktarı
balance.debt_amount        # => Money($200.00)
balance.debt_amount_cents  # => 20000

# Kredi limiti güncelle
balance.update_credit_limit!(200000)

# Bakiye özeti
balance.summary
# => {
#   balance: "$500.00",
#   credit_limit: "$1,000.00",
#   available_balance: "$1,500.00",
#   debt: "$0.00",
#   status: "positive",
#   ...
# }
```

**Scope'lar:**
```ruby
DealerBalance.with_positive_balance  # Pozitif bakiyeli dealer'lar
DealerBalance.with_negative_balance  # Borçlu dealer'lar
DealerBalance.over_credit_limit      # Limiti aşmış dealer'lar
```

**Bakiye Durumları:**
- `positive`: Bakiye pozitif (dealer'ın lehine)
- `negative`: Bakiye negatif ama limit içinde (borçlu)
- `over_limit`: Kredi limitini aşmış

## 🔧 User Model İlişkileri

User modeline B2B ilişkileri eklendi:

```ruby
# B2B Associations (sadece dealer'lar için)
has_many :dealer_discounts, class_name: 'B2b::DealerDiscount', foreign_key: :dealer_id
has_one :dealer_balance, class_name: 'B2b::DealerBalance', foreign_key: :dealer_id

# Callback - Dealer oluşturulduğunda otomatik bakiye oluştur
after_create :create_dealer_balance_if_dealer

# Helper metodlar
user.has_discount_for?(product)           # => true/false
user.discount_for(product)                # => DealerDiscount veya nil
user.ensure_dealer_balance!               # Bakiye yoksa oluştur
```

## 💰 OrderPriceCalculator - B2B Desteği

OrderPriceCalculator servisi dealer'lar için genişletildi:

### Dealer Avantajları

1. **Otomatik İndirim Uygulaması**
   ```ruby
   # Order'daki her ürün için dealer indirimi kontrol edilir
   discount = user.discount_for(product)
   discounted_price = discount.calculate_discounted_price(original_price)
   ```

2. **Düşük Ücretsiz Kargo Limiti**
   ```ruby
   # Normal: 200 TL üzeri ücretsiz
   # Dealer: 100 TL üzeri ücretsiz
   DEALER_FREE_SHIPPING_THRESHOLD = 10000  # $100
   ```

3. **Preview Metodunda B2B Bilgileri**
   ```ruby
   calculator.preview
   # => {
   #   ...
   #   is_dealer: true,
   #   dealer_discount_cents: 15000,
   #   dealer_discount: "$150.00",
   #   dealer_balance: { ... }
   # }
   ```

### Fiyat Hesaplama Formülü (Dealer)

```
Ara Toplam = Σ(order_lines.total_cents)
Dealer İndirimi = Σ(her ürün için indirim tutarı)
Kargo = subtotal >= $100 ? $0 : $30
Vergi = (Ara Toplam - Dealer İndirimi + Kargo) × 0.18
──────────────────────────────────────────────────
Genel Toplam = Ara Toplam - Dealer İndirimi + Kargo + Vergi
```

## 🛒 API Endpoints

### Dealer Discounts

#### 1. İndirimleri Listele

```bash
GET /api/v1/b2b/dealer_discounts
Authorization: Bearer {TOKEN}
```

**Yetki:**
- Dealer: Sadece kendi indirimlerini görebilir
- Admin: Tüm indirimleri görebilir

**Response:**
```json
{
  "data": [
    {
      "type": "dealer_discounts",
      "id": "1",
      "attributes": {
        "dealer_id": 3,
        "dealer_name": "Dealer Smith",
        "dealer_email": "dealer@example.com",
        "product_id": 1,
        "product_title": "MacBook Pro 16\"",
        "product_sku": "MBP-16-M2",
        "discount_percent": 10.0,
        "formatted_discount": "10.0%",
        "active": true
      }
    }
  ],
  "meta": {
    "total": 4
  }
}
```

#### 2. İndirim Detayı

```bash
GET /api/v1/b2b/dealer_discounts/:id
Authorization: Bearer {TOKEN}
```

#### 3. İndirim Oluştur (Admin)

```bash
POST /api/v1/b2b/dealer_discounts
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json

{
  "dealer_id": 3,
  "product_id": 1,
  "discount_percent": 15.5
}
```

**Response:**
```json
{
  "message": "Dealer discount created successfully",
  "data": { ... }
}
```

**Hata Durumları:**
- `422`: Validasyon hatası (ör: aynı dealer+product zaten var)
- `403`: Yetki hatası (admin değil)
- `404`: Dealer veya product bulunamadı

#### 4. İndirim Güncelle (Admin)

```bash
PATCH /api/v1/b2b/dealer_discounts/:id
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json

{
  "discount_percent": 20.0
}
```

#### 5. İndirim Sil (Admin)

```bash
DELETE /api/v1/b2b/dealer_discounts/:id
Authorization: Bearer {ADMIN_TOKEN}
```

#### 6. İndirimi Aktif/Pasif Yap (Admin)

```bash
PATCH /api/v1/b2b/dealer_discounts/:id/toggle_active
Authorization: Bearer {ADMIN_TOKEN}
```

### Dealer Balances

#### 1. Tüm Bakiyeleri Listele (Admin)

```bash
GET /api/v1/b2b/dealer_balances
Authorization: Bearer {ADMIN_TOKEN}
```

**Response:**
```json
{
  "data": [...],
  "meta": {
    "total": 5,
    "total_balance_cents": 250000,
    "positive_balances": 3,
    "negative_balances": 2,
    "over_limit": 0
  }
}
```

#### 2. Bakiye Detayı

```bash
GET /api/v1/b2b/dealer_balances/:id
Authorization: Bearer {TOKEN}
```

**Yetki:**
- Dealer: Sadece kendi bakiyesini görebilir
- Admin: Tüm bakiyeleri görebilir

**Response:**
```json
{
  "data": {
    "type": "dealer_balances",
    "id": "1",
    "attributes": {
      "dealer_id": 3,
      "dealer_name": "Dealer Smith",
      "balance": "$500.00",
      "balance_cents": 50000,
      "credit_limit": "$1,000.00",
      "credit_limit_cents": 100000,
      "available_balance": "$1,500.00",
      "available_balance_cents": 150000,
      "currency": "USD",
      "status": "positive",
      "positive_balance": true,
      "negative_balance": false,
      "over_limit": false,
      "debt": "$0.00",
      "debt_cents": 0,
      "last_transaction_at": "2023-10-10T15:30:00Z"
    }
  },
  "meta": {
    "balance": "$500.00",
    "credit_limit": "$1,000.00",
    "available_balance": "$1,500.00",
    ...
  }
}
```

#### 3. Kendi Bakiyemi Gör (Dealer)

```bash
GET /api/v1/b2b/my_balance
Authorization: Bearer {DEALER_TOKEN}
```

#### 4. Bakiyeye Para Ekle (Admin)

```bash
POST /api/v1/b2b/dealer_balances/:id/add_credit
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json

{
  "amount_cents": 100000,
  "note": "Fatura #12345 ödemesi"
}
```

**Response:**
```json
{
  "message": "Credit added successfully",
  "data": { ... },
  "meta": { ... }
}
```

**İşlem Log'u:**
```
💰 DEALER BALANCE TRANSACTION
==============================
Dealer: Dealer Smith (dealer@example.com)
Type: CREDIT
Amount: $1,000.00
Balance Before: $500.00
Balance After: $1,500.00
Note: Fatura #12345 ödemesi
Time: 2023-10-10 15:30:00 UTC
==============================
```

#### 5. Kredi Limiti Güncelle (Admin)

```bash
PATCH /api/v1/b2b/dealer_balances/:id/update_credit_limit
Authorization: Bearer {ADMIN_TOKEN}
Content-Type: application/json

{
  "credit_limit_cents": 200000
}
```

## 🛒 Sepet & Checkout ile Entegrasyon

### Dealer Sepetinde Otomatik İndirim

Dealer bir ürünü sepete eklediğinde:

1. OrderLine oluşturulur (normal fiyat ile)
2. `OrderPriceCalculator` çalışır
3. Dealer'ın o ürün için indirimi var mı kontrol edilir
4. Varsa otomatik olarak uygulanır
5. Vergi hesaplaması indirimli fiyat üzerinden yapılır

**Örnek:**
```bash
# Dealer login
curl -X POST /api/users/sign_in ...

# Sepete ürün ekle
curl -X POST /api/cart/add \
  -H "Authorization: Bearer DEALER_TOKEN" \
  -d '{"product_id": 1, "quantity": 2}'

# Response'da dealer indirimi görünür
{
  "data": {
    "attributes": {
      "subtotal": "$5,000.00",
      "dealer_discount": "$500.00",    # %10 indirim
      "shipping": "$0.00",              # 100 TL üzeri ücretsiz
      "tax": "$810.00",                 # (5000-500) × 0.18
      "total": "$5,310.00"
    }
  }
}
```

### Checkout Akışı (Dealer)

```
1. Sepete ürün ekle
   └─> Otomatik dealer indirimi uygulanır

2. Checkout başlat
   └─> Bakiye kontrolü yapılır
   └─> Yeterli bakiye varsa devam et

3. Ödeme onayla
   └─> Bakiyeden tutar düşülür (deduct!)
   └─> Order durumu 'paid' olur
   └─> OrderConfirmationJob tetiklenir

4. Bakiye log'u oluşturulur
   └─> Type: DEBIT
   └─> Amount: $5,310.00
   └─> Balance Before: $1,500.00
   └─> Balance After: -$3,810.00
```

## 📊 Seed Verileri

Seeds dosyası dealer için örnek data oluşturur:

**Dealer Bakiyesi:**
- Başlangıç bakiyesi: $500.00
- Kredi limiti: $1,000.00
- Kullanılabilir toplam: $1,500.00

**Dealer İndirimleri:**
| Ürün | İndirim |
|------|---------|
| MacBook Pro 16" | %10 |
| Dell XPS 15 | %12.5 |
| Logitech MX Master 3 | %20 |
| Keychron K2 | %15 |

```bash
rails db:seed
```

## 🧪 Test Senaryoları

### Test Script

```bash
./test_b2b_api.sh
```

**Test Akışı:**
1. ✅ Dealer login
2. ✅ Dealer bakiyesini gör
3. ✅ Dealer indirimlerini listele
4. ✅ Sepete ürün ekle (otomatik indirim)
5. ✅ Sepeti görüntüle (dealer fiyatlandırması)
6. ✅ İndirimli ürün ekle (Mouse %20)
7. ✅ Checkout (dealer indirimleri ile)
8. ✅ Admin login
9. ✅ Admin tüm bakiyeleri gör
10. ✅ Admin bakiyeye para ekle
11. ✅ Admin yeni indirim oluştur
12. ✅ Admin kredi limiti güncelle

### Manuel Test

```bash
# 1. Dealer olarak giriş yap
curl -X POST http://localhost:3000/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"dealer@example.com","password":"password123"}}'

# 2. İndirimleri gör
curl http://localhost:3000/api/v1/b2b/dealer_discounts \
  -H "Authorization: Bearer TOKEN"

# 3. Bakiyeyi gör
curl http://localhost:3000/api/v1/b2b/my_balance \
  -H "Authorization: Bearer TOKEN"

# 4. Sepete indirimli ürün ekle
curl -X POST http://localhost:3000/api/cart/add \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"variant_id":1,"quantity":2}'

# 5. Sepeti kontrol et (dealer indirimleri uygulanmış olmalı)
curl http://localhost:3000/api/cart \
  -H "Authorization: Bearer TOKEN"
```

## 📈 İstatistikler & Raporlama

### Dealer Performans Metrikleri

```ruby
# Toplam dealer sayısı
User.dealer.count

# Aktif indirimli dealer sayısı
B2b::DealerDiscount.select(:dealer_id).distinct.count

# Toplam indirim tutarı (son ay)
# (Bunu hesaplamak için order_lines'a dealer_discount_cents kolonu eklenebilir)

# En çok indirim alan dealer
# En çok borçlu dealer
B2b::DealerBalance.with_negative_balance.order(:balance_cents).first

# Kredi limiti aşan dealer'lar
B2b::DealerBalance.over_credit_limit.count
```

## 🚀 Sıradaki Adımlar

### 1. OrderLine'a Dealer İndirim Kolonu

```ruby
# Migration
add_column :order_lines, :dealer_discount_cents, :integer, default: 0

# Model
monetize :dealer_discount_cents, as: :dealer_discount
```

### 2. Dealer Analytics Dashboard

- Aylık sipariş raporu
- İndirim kullanım istatistikleri
- Bakiye hareketleri grafiği
- Borç tahsilat raporu

### 3. Otomatik Bakiye Bildirimleri

```ruby
# Bakiye düşük olduğunda
if balance.available_balance_cents < 10000
  DealerLowBalanceNotificationJob.perform_later(dealer.id)
end

# Limit aşımı durumunda
if balance.over_limit?
  DealerOverLimitAlertJob.perform_later(dealer.id)
end
```

### 4. Toplu İndirim Tanımlama

```ruby
# Bir kategorideki tüm ürünlere %10 indirim
category.products.each do |product|
  dealer.dealer_discounts.create!(
    product: product,
    discount_percent: 10.0
  )
end
```

### 5. Zaman Bazlı İndirimler

```ruby
# Migration
add_column :dealer_discounts, :valid_from, :datetime
add_column :dealer_discounts, :valid_until, :datetime

# Scope
scope :currently_valid, -> {
  where('valid_from <= ? AND (valid_until IS NULL OR valid_until >= ?)', Time.current, Time.current)
}
```

### 6. Dealer Kategorileri

```ruby
# Örn: Silver, Gold, Platinum dealer'lar
# Her kategoride farklı avantajlar
enum dealer_category: { silver: 0, gold: 1, platinum: 2 }

# Platinum dealer'lar için ücretsiz kargo her zaman
# Gold dealer'lar için %5 ekstra indirim
```

## 📚 Kod Örnekleri

### Dealer İçin Sipariş Oluşturma

```ruby
dealer = User.find_by(email: 'dealer@example.com')
order = dealer.orders.create!(status: :cart, currency: 'USD')

# Ürün ekle
product = Catalog::Product.find(1)
variant = product.variants.first

order.order_lines.create!(
  product: product,
  variant: variant,
  quantity: 2
)

# Fiyatları hesapla (dealer indirimleri otomatik uygulanır)
calculator = Orders::OrderPriceCalculator.new(order)
calculator.calculate!

# Preview'da dealer bilgileri
preview = calculator.preview
puts preview[:dealer_discount]  # => "$250.00"
puts preview[:is_dealer]        # => true
```

### Dealer Bakiyesi ile Ödeme

```ruby
dealer = User.dealer.find_by(email: 'dealer@example.com')
balance = dealer.dealer_balance

# Sipariş tutarı
order_total = 500_00  # $500

# Bakiye yeterli mi?
if balance.sufficient_balance?(order_total)
  # Bakiyeden düş
  if balance.deduct!(order_total, note: "Sipariş ##{order.id}")
    order.mark_as_paid!
    Orders::OrderConfirmationJob.perform_later(order.id)
  end
else
  puts "Yetersiz bakiye! Kullanılabilir: #{balance.available_balance.format}"
end
```

### Admin İşlemleri

```ruby
# Yeni dealer indirimi oluştur
dealer = User.dealer.find(3)
product = Catalog::Product.find(1)

discount = B2b::DealerDiscount.create!(
  dealer: dealer,
  product: product,
  discount_percent: 15.0
)

# Dealer'a para ekle
balance = dealer.dealer_balance
balance.add_credit!(1000_00, note: "Fatura #123 ödemesi")

# Kredi limiti artır
balance.update_credit_limit!(2000_00)  # $2,000 limit
```

---

**Hazırlayan:** Commerce Core API Team
**Tarih:** Ekim 2023
**Durum:** ✅ Production Ready
