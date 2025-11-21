# E-Ticaret Sistemi - Checkout & B2B Akış Dokümantasyonu

## 📋 Sistem Özeti

Rails API tabanlı, B2B destekli e-ticaret sistemi

### 🎯 Temel Özellikler
- ✅ Sepet Yönetimi
- ✅ Çoklu Ödeme Yöntemleri
- ✅ B2B Dealer Sistemi (İndirim & Bakiye)
- ✅ Fiyat Hesaplama (KDV, Kargo, İndirimler)
- ✅ Quote/Teklif Sistemi
- ✅ Stok Yönetimi
- ✅ Sipariş Tracking

---

## 🛒 SEPET & CHECKOUT AKIŞI

### 1. Sepet API Endpoints

#### GET /api/cart
Kullanıcının aktif sepetini gösterir.

**Response:**
```json
{
  "data": {
    "type": "cart",
    "id": "123",
    "attributes": {
      "status": "cart",
      "items_count": 3,
      "total_quantity": 5,
      "subtotal": "$450.00",
      "discount": "$45.00",
      "shipping": "$30.00",
      "tax": "$77.40",
      "total": "$512.40",
      "currency": "USD",
      "free_shipping": false,
      "payable": true
    },
    "included": [
      {
        "type": "order_lines",
        "id": "1",
        "attributes": {
          "product_id": 1,
          "product_title": "Deri Menü Kabı",
          "variant_id": 1,
          "variant_name": "A4 - 2 Sayfa",
          "quantity": 2,
          "unit_price": "$225.00",
          "total": "$450.00",
          "note": "Logo baskı var"
        }
      }
    ]
  }
}
```

#### POST /api/cart/add
Sepete ürün ekler.

**Request:**
```json
{
  "product_id": 1,
  "variant_id": 1,  // opsiyonel
  "quantity": 2,
  "note": "Logo baskı istiyorum"  // opsiyonel
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
      "product_title": "Deri Menü Kabı",
      "quantity": 2,
      "unit_price": "$225.00",
      "total": "$450.00"
    }
  },
  "meta": {
    "cart_total_items": 5,
    "cart_total": "$512.40"
  }
}
```

#### PATCH /api/cart/items/:id
Sepetteki ürün miktarını günceller.

**Request:**
```json
{
  "quantity": 3
}
```

#### DELETE /api/cart/items/:id
Sepetten ürün çıkarır.

#### DELETE /api/cart/clear
Sepeti tamamen temizler.

---

### 2. Checkout Akışı

#### GET /api/cart/checkout/preview
Checkout önizlemesi - fiyat detayları ve ödeme yöntemleri

**Response:**
```json
{
  "data": {
    "type": "checkout_preview",
    "attributes": {
      "subtotal_cents": 45000,
      "subtotal": "$450.00",
      "discount_cents": 4500,
      "discount": "$45.00",
      "shipping_cents": 3000,
      "shipping": "$30.00",
      "tax_cents": 7740,
      "tax": "$77.40",
      "total_cents": 51240,
      "total": "$512.40",
      "currency": "USD",
      "items_count": 5,
      "free_shipping": false,
      
      // B2B Bilgileri (dealer ise)
      "is_dealer": true,
      "dealer_discount_cents": 4500,
      "dealer_discount": "$45.00",
      "dealer_balance": {
        "balance": "$1,000.00",
        "credit_limit": "$5,000.00",
        "available_balance": "$6,000.00"
      }
    },
    "payment_methods": [
      {
        "id": "credit_card",
        "name": "Kredi Kartı / Banka Kartı",
        "enabled": true
      },
      {
        "id": "dealer_balance",
        "name": "Dealer Bakiyesi",
        "enabled": true,
        "balance": "$1,000.00",
        "available": "$6,000.00"
      },
      {
        "id": "bank_transfer",
        "name": "Havale / EFT",
        "enabled": true
      },
      {
        "id": "cash_on_delivery",
        "name": "Kapıda Ödeme",
        "enabled": true
      }
    ],
    "can_use_balance": true
  }
}
```

#### POST /api/cart/checkout
Ödeme işlemini başlatır.

**Request:**
```json
{
  "payment_method": "dealer_balance",  // veya "credit_card", "bank_transfer", "cash_on_delivery"
  "shipping_address": {
    "name": "Ahmet Yılmaz",
    "phone": "+905551234567",
    "address_line1": "Atatürk Cad. No:123 Daire:4",
    "address_line2": "Kadıköy",
    "city": "İstanbul",
    "postal_code": "34710",
    "country": "TR"
  },
  "billing_address": {
    // Opsiyonel - belirtilmezse shipping_address kullanılır
  },
  "use_different_billing": false,  // true ise billing_address zorunlu
  "notes": "Logo baskısı için görsel mail ile gönderilecek"
}
```

**Response (Dealer Balance):**
```json
{
  "success": true,
  "message": "Sipariş dealer bakiyenizden ödenmiştir",
  "data": {
    "type": "order",
    "id": "123",
    "attributes": {
      "order_number": "ORD-20231010-000123",
      "status": "paid",
      "payment_method": "dealer_balance",
      "total": "$512.40",
      "paid_at": "2023-10-10T10:30:00Z"
    }
  },
  "payment_method": "dealer_balance",
  "remaining_balance": "$487.60"
}
```

**Response (Credit Card):**
```json
{
  "success": true,
  "message": "İşlem başarılı",
  "data": {
    "type": "order",
    "id": "123",
    "attributes": {
      "order_number": "ORD-20231010-000123",
      "status": "cart",
      "payment_method": "credit_card",
      "total": "$512.40"
    }
  },
  "payment_provider": "paytr",
  "payment_data": {
    "token": "xxxxx",
    "iframe_url": "https://paytr.com/..."
  },
  "next_step": "redirect_to_payment"
}
```

**Response (Bank Transfer):**
```json
{
  "success": true,
  "message": "Sipariş alındı. Ödeme onayından sonra işleme alınacaktır",
  "data": {
    "type": "order",
    "id": "123",
    "attributes": {
      "order_number": "ORD-20231010-000123",
      "status": "cart",
      "payment_method": "bank_transfer",
      "total": "$512.40"
    }
  },
  "payment_method": "bank_transfer",
  "payment_instructions": {
    "bank_name": "İş Bankası",
    "branch": "Kadıköy Şubesi",
    "account_holder": "Paksoy Menü Ltd. Şti.",
    "iban": "TR00 0000 0000 0000 0000 0000 00",
    "reference": "ORD-20231010-000123",
    "amount": "$512.40",
    "note": "Havale açıklamasına sipariş numaranızı yazmayı unutmayın"
  }
}
```

---

## 💰 FİYAT HESAPLAMA SİSTEMİ

### OrderPriceCalculator Service

**Hesaplama Sırası:**
1. **Ara Toplam (Subtotal)**: Tüm ürünlerin toplam fiyatı
2. **İndirim (Discount)**: Dealer indirimleri toplamı (B2B)
3. **Kargo (Shipping)**: 
   - Normal: $200 üzeri ücretsiz
   - Dealer: $100 üzeri ücretsiz
4. **Vergi (Tax)**: (Ara Toplam - İndirim + Kargo) × %18
5. **Toplam (Total)**: Ara Toplam - İndirim + Kargo + Vergi

**Formül:**
```
subtotal = Σ(order_line.total)
discount = Σ(dealer_discount per line)  // B2B only
shipping = subtotal - discount >= threshold ? 0 : 30
tax = (subtotal - discount + shipping) × 0.18
total = subtotal - discount + shipping + tax
```

---

## 👔 B2B DEALER SİSTEMİ

### 1. Dealer Discount (İndirim Sistemi)

Her dealer için ürün bazında indirim tanımlanabilir.

**Model:** `B2b::DealerDiscount`

```ruby
# Örnek: %15 indirim
discount = B2b::DealerDiscount.create!(
  dealer: user,
  product: product,
  discount_percent: 15.0,
  active: true
)

# İndirim tutarını hesapla
discount.discount_amount(45000)  # => 6750 cents ($67.50)
```

**Database:**
```sql
dealer_discounts
  - dealer_id (user_id)
  - product_id
  - discount_percent (0-100)
  - active (boolean)
```

### 2. Dealer Balance (Bakiye Sistemi)

Dealer'ların cari hesabı ve kredi limiti.

**Model:** `B2b::DealerBalance`

```ruby
balance = user.dealer_balance

# Bakiye bilgileri
balance.balance              # => $1,000.00
balance.credit_limit         # => $5,000.00
balance.available_balance    # => $6,000.00

# Bakiye işlemleri
balance.topup!(10000, note: "Manuel yükleme")          # Bakiye ekle
balance.deduct!(5000, note: "Sipariş", order_id: 123) # Bakiyeden düş
balance.add_credit!(10000, note: "Ödeme alındı")      # Kredi ekle
```

**Database:**
```sql
dealer_balances
  - dealer_id (user_id)
  - balance_cents (integer)
  - credit_limit_cents (integer)
  - currency (string, default: 'USD')
  - last_transaction_at (datetime)
```

**Transactions:**
```sql
dealer_balance_transactions
  - dealer_balance_id
  - transaction_type (credit, debit, topup, payment)
  - amount_cents
  - note
  - order_id (nullable)
```

---

## 📝 QUOTE/TEKLİF SİSTEMİ

Adminler müşteriler adına teklif oluşturabilir.

### API Endpoints

#### POST /api/v1/quotes
Admin teklif oluşturur.

**Request:**
```json
{
  "quote": {
    "user_id": 5,
    "valid_until": "2023-11-10",
    "notes": "Toplu alım indirimi uygulandı"
  },
  "quote_lines": [
    {
      "product_id": 1,
      "variant_id": 1,
      "quantity": 100,
      "note": "Logo baskı dahil"
    },
    {
      "product_id": 2,
      "quantity": 50
    }
  ]
}
```

#### GET /api/v1/quotes
Teklifleri listele (admin: tümü, user: kendisine ait)

#### GET /api/v1/quotes/:id
Tek teklif detayı

#### POST /api/v1/quotes/:id/send_quote
Admin teklifi müşteriye gönderir (draft → sent)

#### POST /api/v1/quotes/:id/accept
Müşteri teklifi kabul eder ve siparişe dönüştürür

**Response:**
```json
{
  "message": "Teklif kabul edildi ve siparişe dönüştürüldü",
  "data": {
    "quote": { ... },
    "order": {
      "id": 123,
      "order_number": "ORD-20231010-000123",
      "status": "cart",
      "total": "$5,120.00"
    }
  }
}
```

#### POST /api/v1/quotes/:id/reject
Müşteri teklifi reddeder

---

## 🔄 SİPARİŞ DURUMLARI

### Order Status Flow

```
cart → paid → shipped
  ↓
cancelled
```

**Durumlar:**
- `cart`: Sepet aşaması (henüz ödeme yapılmamış)
- `paid`: Ödeme alındı, işleme hazır
- `shipped`: Kargoya verildi
- `cancelled`: İptal edildi

### Production Status (Üretim Takibi)

```
pending → in_production → ready → shipped
```

---

## 💳 ÖDEME YÖNTEMLERİ

### 1. Kredi Kartı (PayTR)
- PayTR entegrasyonu ile 3D Secure ödeme
- iframe içinde ödeme ekranı
- Webhook ile otomatik onay

### 2. Dealer Bakiyesi (B2B)
- Dealer'ın mevcut bakiyesi + kredi limiti
- Anında onay
- İşlem logu kaydedilir

### 3. Havale/EFT
- Banka bilgileri gösterilir
- Manuel onay gerekir
- Sipariş numarası referans olarak kullanılır

### 4. Kapıda Ödeme
- Maksimum $500 tutarla sınırlı
- Otomatik onay

---

## 📊 VERİ MODELLERİ

### Orders::Order
```ruby
- id
- user_id
- status (cart, paid, shipped, cancelled)
- payment_method (credit_card, dealer_balance, bank_transfer, cash_on_delivery)
- payment_status (pending, completed, failed)
- subtotal_cents
- discount_cents      # Yeni eklendi
- shipping_cents
- tax_cents
- total_cents
- currency
- shipping_address (jsonb)
- billing_address (jsonb)
- notes
- metadata (jsonb)
- paid_at
- shipped_at
- cancelled_at
- created_at
- updated_at
```

### Orders::OrderLine
```ruby
- id
- order_id
- product_id
- variant_id
- product_title
- quantity
- unit_price_cents
- total_cents
- note
- created_at
- updated_at
```

### B2b::DealerBalance
```ruby
- id
- dealer_id (user_id)
- balance_cents
- credit_limit_cents
- currency
- last_transaction_at
- created_at
- updated_at
```

### B2b::DealerDiscount
```ruby
- id
- dealer_id (user_id)
- product_id
- discount_percent
- active
- created_at
- updated_at
```

### Quote
```ruby
- id
- user_id
- created_by_id (admin user_id)
- quote_number
- status (draft, sent, accepted, rejected, expired)
- valid_until
- subtotal_cents
- tax_cents
- shipping_cents
- total_cents
- currency
- notes
- created_at
- updated_at
```

---

## 🔐 YETKİLENDİRME

### Roller
- `admin`: Tüm yetkilere sahip
- `dealer`: B2B bayiler (indirim + bakiye)
- `customer`: Normal müşteriler

### Endpoint Yetkileri

**Herkes:**
- GET /api/cart
- POST /api/cart/add
- GET /api/products
- GET /api/categories

**Authenticated:**
- POST /api/cart/checkout
- GET /api/v1/quotes (sadece kendi teklifleri)

**Admin Only:**
- POST /api/v1/quotes
- POST /api/v1/quotes/:id/send_quote
- All admin panels

**Dealer Only:**
- payment_method: "dealer_balance"
- Dealer discount'lar otomatik uygulanır

---

## 📈 KULLANIM ÖRNEKLERİ

### Senaryo 1: Normal Müşteri Alışverişi

```bash
# 1. Sepete ürün ekle
POST /api/cart/add
{
  "product_id": 1,
  "quantity": 2
}

# 2. Sepeti görüntüle
GET /api/cart

# 3. Checkout önizleme
GET /api/cart/checkout/preview

# 4. Checkout - Kredi kartı ile
POST /api/cart/checkout
{
  "payment_method": "credit_card",
  "shipping_address": { ... }
}

# 5. PayTR iframe'e yönlendir
# Ödeme başarılı olunca webhook gelir → order.status = paid
```

### Senaryo 2: Dealer B2B Alışverişi

```bash
# 1. Sepete ürün ekle
POST /api/cart/add
{
  "product_id": 1,
  "quantity": 50
}

# 2. Checkout önizleme (dealer indirimi otomatik uygulanır)
GET /api/cart/checkout/preview
# Response: %10 indirim uygulandı, ücretsiz kargo

# 3. Dealer bakiyesi ile öde
POST /api/cart/checkout
{
  "payment_method": "dealer_balance",
  "shipping_address": { ... }
}

# 4. Anında onaylanır → order.status = paid
# Dealer balance'dan düşülür
```

### Senaryo 3: Admin Teklif Oluşturma

```bash
# 1. Admin teklif oluşturur
POST /api/v1/quotes
{
  "quote": {
    "user_id": 5,
    "valid_until": "2023-11-10"
  },
  "quote_lines": [
    { "product_id": 1, "quantity": 100 }
  ]
}

# 2. Admin teklifi gönderir
POST /api/v1/quotes/123/send_quote

# 3. Müşteri teklifi görür
GET /api/v1/quotes/123

# 4. Müşteri kabul eder
POST /api/v1/quotes/123/accept

# 5. Otomatik sipariş oluşturulur
# Quote.status = accepted
# Order.status = cart (devam eder)
```

---

## 🚀 NEXT STEPS

### Yapılacaklar:
1. ✅ Order'a discount_cents eklendi
2. ✅ OrderPriceCalculator'da dealer indirimleri Order'a kaydediliyor
3. ✅ CheckoutService oluşturuldu
4. ✅ Quote controller oluşturuldu
5. ⏳ PayTR webhook endpoint
6. ⏳ Email bildirimleri
7. ⏳ Frontend entegrasyonu

### Öneriler:
- Sipariş tracking sayfası
- Dealer panel (bakiye, indirimler, siparişler)
- Quote email template'leri
- Admin dashboard (sipariş yönetimi)
- Kargo entegrasyonu (Aras, Yurtiçi vb.)
