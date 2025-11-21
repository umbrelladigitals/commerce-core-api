# 🎯 Admin Panel API - Hızlı Başlangıç

## 🚀 5 Dakikada Başlangıç

### 1. Database Migration (Tamamlandı ✅)
```bash
rails db:migrate
```

### 2. Admin Olarak Login
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"admin@test.com","password":"password123"}}'
```

### 3. Hızlı Test
```bash
./test_admin_api.sh
```

## 📋 Temel Kullanım

### Müşteri Adına Sipariş Oluştur

```bash
curl -X POST http://localhost:3000/api/v1/admin/orders \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 2,
    "order_lines": [
      {"product_id": 1, "quantity": 2}
    ],
    "admin_note": "Telefon siparişi"
  }'
```

### Not Ekle

```bash
curl -X POST http://localhost:3000/api/v1/admin/notes \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "note": {
      "note": "Müşteri ile görüşüldü",
      "related_type": "Orders::Order",
      "related_id": 123
    }
  }'
```

### Teklif Oluştur

```bash
curl -X POST http://localhost:3000/api/v1/admin/quotes \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 2,
    "quote_lines": [
      {
        "product_id": 1,
        "quantity": 10,
        "unit_price_cents": 250000
      }
    ]
  }'
```

## 🔌 Tüm Endpoint'ler

### Admin Notes (Notlar)
```
GET    /api/v1/admin/notes           # Liste
POST   /api/v1/admin/notes           # Oluştur
GET    /api/v1/admin/notes/:id       # Detay
PATCH  /api/v1/admin/notes/:id       # Güncelle
DELETE /api/v1/admin/notes/:id       # Sil
```

### Admin Orders (Siparişler)
```
GET    /api/v1/admin/orders          # Liste
POST   /api/v1/admin/orders          # Müşteri adına oluştur
GET    /api/v1/admin/orders/:id      # Detay
PATCH  /api/v1/admin/orders/:id      # Güncelle
DELETE /api/v1/admin/orders/:id      # Sil
```

### Admin Quotes (Teklifler)
```
GET    /api/v1/admin/quotes              # Liste
POST   /api/v1/admin/quotes              # Oluştur
GET    /api/v1/admin/quotes/:id          # Detay
PATCH  /api/v1/admin/quotes/:id          # Güncelle
DELETE /api/v1/admin/quotes/:id          # Sil
POST   /api/v1/admin/quotes/:id/send     # Gönder
POST   /api/v1/admin/quotes/:id/convert  # Siparişe dönüştür
```

## 💻 Frontend Örnek (React)

```javascript
// Admin order creation
async function createOrder(userId, items) {
  const response = await fetch('/api/v1/admin/orders', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      user_id: userId,
      order_lines: items
    })
  });
  return response.json();
}

// Add note
async function addNote(entityType, entityId, noteText) {
  const response = await fetch('/api/v1/admin/notes', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      note: {
        note: noteText,
        related_type: entityType,
        related_id: entityId
      }
    })
  });
  return response.json();
}

// Create quote
async function createQuote(userId, lines) {
  const response = await fetch('/api/v1/admin/quotes', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      user_id: userId,
      quote_lines: lines
    })
  });
  return response.json();
}
```

## 📊 Veri Modelleri

### AdminNote
- Sipariş, müşteri, teklif hakkında notlar
- Polymorphic ilişki (her şeye not eklenebilir)
- Yazar bilgisi otomatik

### Quote
- Müşteri/bayi için teklif
- Status: draft, sent, accepted, rejected, expired
- Geçerlilik tarihi takibi
- Siparişe dönüştürme

### QuoteLine
- Teklif satırları
- Özel fiyatlandırma
- Ürün/varyant desteği

## 🔐 Yetkilendirme

Tüm admin endpoint'leri için:
- ✅ JWT token gerekli
- ✅ Admin rolü gerekli
- ❌ Customer/Dealer erişemez

```javascript
// Header format
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

## 🎯 Kullanım Senaryoları

### 1. Telefon Siparişi
1. Müşteri telefon ile arar
2. Admin sisteme girer
3. POST `/api/v1/admin/orders` ile sipariş oluşturur
4. Admin notu ekler: "Telefon siparişi - Özel paket"

### 2. Özel Teklif
1. Bayi özel fiyat ister
2. Admin teklif oluşturur (draft)
3. Fiyatları özelleştirir
4. POST `/api/v1/admin/quotes/:id/send` ile gönderir
5. Bayi kabul ederse convert eder

### 3. Sipariş Takibi
1. Müşteri durumu sorar
2. Admin GET `/api/v1/admin/orders/:id` ile detay alır
3. Not ekler: "Müşteri ile görüşüldü, kargo bekliyor"
4. PATCH ile durumu günceller

## 📝 Filtreleme Örnekleri

```javascript
// Belirli müşterinin notlarını al
GET /api/v1/admin/notes?related_type=User&related_id=5

// Siparişe ait notları al
GET /api/v1/admin/notes?related_type=Orders::Order&related_id=123

// Belirli bayinin siparişleri
GET /api/v1/admin/orders?user_id=5&status=paid

// Bugünkü siparişler
GET /api/v1/admin/orders?start_date=2023-10-10&end_date=2023-10-10

// Gönderilmiş teklifler
GET /api/v1/admin/quotes?status=sent
```

## ⚠️ Önemli Notlar

- **Quote Status:** Sadece `sent` teklifler siparişe dönüştürülebilir
- **Order Delete:** Sadece `cart` durumundaki siparişler silinebilir
- **Quote Delete:** Sadece `draft` teklifler silinebilir
- **Polymorphic Types:** "Orders::Order", "User", "Quote" gibi tam namespace kullanın
- **Money Cents:** Fiyatlar cent/kuruş cinsinden (250000 = $2,500.00)

## 🔗 İlgili Dokümantasyon

- **Detaylı API:** [ADMIN_PANEL_API.md](ADMIN_PANEL_API.md)
- **Checklist:** [ADMIN_PANEL_CHECKLIST.md](ADMIN_PANEL_CHECKLIST.md)
- **Test Script:** `./test_admin_api.sh`

## 🎉 Hazırsınız!

Admin panel API'si kullanıma hazır. React/Vue/Angular ile frontend geliştirebilirsiniz.

```bash
# Test et
./test_admin_api.sh
```
