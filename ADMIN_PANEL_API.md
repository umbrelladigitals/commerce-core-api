# Admin Panel API Dokümantasyonu

Admin panel API'si yöneticilerin müşteri/bayi adına sipariş oluşturması, notlar eklemesi ve teklif (proforma) oluşturması için geliştirilmiştir.

## 🎯 Özellikler

### 1. **Sipariş Yönetimi**
- Müşteri/bayi adına sipariş oluşturma
- Tüm siparişleri listeleme ve filtreleme
- Sipariş durumu güncelleme
- Sipariş detaylarını görüntüleme

### 2. **Admin Notları**
- Sipariş, müşteri, bayi hakkında notlar ekleme
- Notları listeleme ve filtreleme
- Not güncelleme ve silme
- Polymorphic ilişki (her türlü kayda not eklenebilir)

### 3. **Teklifler (Proforma)**
- Müşteri/bayi için teklif oluşturma
- Teklif gönderme (draft → sent)
- Teklifi siparişe dönüştürme
- Teklif geçerlilik takibi

## 📊 Veritabanı Modelleri

### AdminNote
```ruby
{
  id: bigint,
  note: text,                    # Not içeriği
  related_type: string,          # İlişkili model (polymorphic)
  related_id: bigint,            # İlişkili kayıt ID
  author_id: bigint,             # Notu yazan admin
  created_at: datetime,
  updated_at: datetime
}
```

### Quote
```ruby
{
  id: bigint,
  user_id: bigint,               # Teklif verilen müşteri/bayi
  created_by_id: bigint,         # Teklifi oluşturan admin
  quote_number: string,          # QUO-20231010-001
  status: integer,               # 0:draft, 1:sent, 2:accepted, 3:rejected, 4:expired
  valid_until: date,             # Geçerlilik tarihi
  notes: text,                   # Teklif notları
  subtotal_cents: integer,
  tax_cents: integer,
  shipping_cents: integer,
  total_cents: integer,
  currency: string,
  created_at: datetime,
  updated_at: datetime
}
```

### QuoteLine
```ruby
{
  id: bigint,
  quote_id: bigint,
  product_id: bigint,
  variant_id: bigint (optional),
  product_title: string,
  variant_name: string (optional),
  quantity: integer,
  unit_price_cents: integer,
  total_cents: integer,
  note: text,
  created_at: datetime,
  updated_at: datetime
}
```

## 🔌 API Endpoints

### Admin Notes

#### Tüm Notları Listele
```http
GET /api/v1/admin/notes
Authorization: Bearer {admin_token}

Query Parameters:
- related_type: string (örn: "Orders::Order", "User")
- related_id: integer
- author_id: integer
- page: integer

Response:
{
  "data": [
    {
      "type": "admin_notes",
      "id": "1",
      "attributes": {
        "note": "Müşteri özel iskonto talep etti",
        "related_type": "Orders::Order",
        "related_id": 123,
        "author_name": "Admin User",
        "author_email": "admin@test.com",
        "created_at": "2023-10-10T10:00:00Z",
        "updated_at": "2023-10-10T10:00:00Z"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 100
  }
}
```

#### Not Oluştur
```http
POST /api/v1/admin/notes
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "note": {
    "note": "Müşteri ile görüşüldü",
    "related_type": "Orders::Order",
    "related_id": 123
  }
}

Response:
{
  "message": "Not başarıyla oluşturuldu",
  "data": { ... }
}
```

#### Not Güncelle
```http
PATCH /api/v1/admin/notes/:id
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "note": {
    "note": "Güncellenen not içeriği"
  }
}
```

#### Not Sil
```http
DELETE /api/v1/admin/notes/:id
Authorization: Bearer {admin_token}

Response:
{
  "message": "Not silindi"
}
```

---

### Admin Orders

#### Müşteri/Bayi Adına Sipariş Oluştur
```http
POST /api/v1/admin/orders
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "user_id": 5,
  "status": "cart",
  "currency": "USD",
  "order_lines": [
    {
      "product_id": 1,
      "variant_id": 2,
      "quantity": 3,
      "note": "Özel paket"
    }
  ],
  "admin_note": "Telefon ile alınan sipariş"
}

Response:
{
  "message": "Sipariş başarıyla oluşturuldu",
  "data": {
    "type": "orders",
    "id": "123",
    "attributes": {
      "order_number": "ORD-20231010-000123",
      "status": "cart",
      "total": "$500.00",
      ...
    }
  }
}
```

#### Tüm Siparişleri Listele
```http
GET /api/v1/admin/orders
Authorization: Bearer {admin_token}

Query Parameters:
- user_id: integer
- status: string (cart, paid, shipped, cancelled)
- start_date: date (YYYY-MM-DD)
- end_date: date (YYYY-MM-DD)
- page: integer

Response:
{
  "data": [ ... ],
  "meta": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 200
  }
}
```

#### Sipariş Detayı
```http
GET /api/v1/admin/orders/:id
Authorization: Bearer {admin_token}

Response:
{
  "data": {
    "type": "orders",
    "id": "123",
    "attributes": { ... },
    "included": {
      "user": { ... },
      "admin_notes": [ ... ]
    }
  }
}
```

#### Sipariş Durumu Güncelle
```http
PATCH /api/v1/admin/orders/:id
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "order": {
    "status": "paid"
  },
  "admin_note": "Manuel ödeme onaylandı"
}

Response:
{
  "message": "Sipariş güncellendi",
  "data": { ... }
}
```

---

### Quotes (Teklifler)

#### Teklif Oluştur
```http
POST /api/v1/admin/quotes
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "user_id": 5,
  "status": "draft",
  "notes": "Özel bayi fiyatlandırması",
  "valid_until": "2023-11-10",
  "currency": "USD",
  "quote_lines": [
    {
      "product_id": 1,
      "variant_id": 2,
      "quantity": 10,
      "unit_price_cents": 250000,
      "note": "Toplu alım indirimi"
    }
  ],
  "admin_note": "Özel kampanya teklifi"
}

Response:
{
  "message": "Teklif başarıyla oluşturuldu",
  "data": {
    "type": "quotes",
    "id": "1",
    "attributes": {
      "quote_number": "QUO-20231010-001",
      "status": "draft",
      "total": "$2,500.00",
      "valid_until": "2023-11-10",
      ...
    }
  }
}
```

#### Teklif Listele
```http
GET /api/v1/admin/quotes
Authorization: Bearer {admin_token}

Query Parameters:
- user_id: integer
- status: string (draft, sent, accepted, rejected, expired)
- created_by_id: integer
- page: integer

Response:
{
  "data": [ ... ],
  "meta": { ... }
}
```

#### Teklif Detayı
```http
GET /api/v1/admin/quotes/:id
Authorization: Bearer {admin_token}

Response:
{
  "data": {
    "type": "quotes",
    "id": "1",
    "attributes": { ... },
    "included": {
      "user": { ... },
      "created_by": { ... },
      "quote_lines": [ ... ],
      "admin_notes": [ ... ]
    }
  }
}
```

#### Teklifi Gönder (Draft → Sent)
```http
POST /api/v1/admin/quotes/:id/send
Authorization: Bearer {admin_token}

Response:
{
  "message": "Teklif gönderildi",
  "data": { ... }
}
```

#### Teklifi Siparişe Dönüştür
```http
POST /api/v1/admin/quotes/:id/convert
Authorization: Bearer {admin_token}

Response:
{
  "message": "Teklif siparişe dönüştürüldü",
  "data": {
    "quote_id": 1,
    "order_id": 456,
    "order_number": "ORD-20231010-000456"
  }
}
```

#### Teklif Güncelle
```http
PATCH /api/v1/admin/quotes/:id
Authorization: Bearer {admin_token}
Content-Type: application/json

{
  "quote": {
    "status": "rejected",
    "notes": "Güncellenen notlar"
  },
  "admin_note": "Müşteri reddetti"
}
```

#### Teklif Sil (Sadece Draft)
```http
DELETE /api/v1/admin/quotes/:id
Authorization: Bearer {admin_token}

Response:
{
  "message": "Teklif silindi"
}
```

## 🔐 Yetkilendirme

Tüm admin endpoint'leri JWT token ve admin rolü gerektirir:

```javascript
// Authorization header
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...

// User role check
current_user.admin? // => true
```

Admin olmayan kullanıcılar `403 Forbidden` hatası alır.

## 🎨 Frontend Entegrasyon Örnekleri

### React - Sipariş Oluşturma

```jsx
async function createOrderForCustomer(userId, orderData) {
  const response = await fetch('/api/v1/admin/orders', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      user_id: userId,
      order_lines: orderData.items,
      admin_note: orderData.note
    })
  });
  
  return response.json();
}
```

### React - Not Ekleme

```jsx
async function addNoteToOrder(orderId, noteText) {
  const response = await fetch('/api/v1/admin/notes', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      note: {
        note: noteText,
        related_type: 'Orders::Order',
        related_id: orderId
      }
    })
  });
  
  return response.json();
}
```

### React - Teklif Oluşturma ve Gönderme

```jsx
async function createAndSendQuote(userId, quoteData) {
  // 1. Create quote
  const createResponse = await fetch('/api/v1/admin/quotes', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      user_id: userId,
      ...quoteData
    })
  });
  
  const quote = await createResponse.json();
  const quoteId = quote.data.id;
  
  // 2. Send quote
  const sendResponse = await fetch(`/api/v1/admin/quotes/${quoteId}/send`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  return sendResponse.json();
}
```

## 🧪 Test

```bash
# Test script'ini çalıştır
./test_admin_api.sh

# Manuel test
curl -X POST http://localhost:3000/api/v1/admin/orders \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_id":2,"order_lines":[{"product_id":1,"quantity":2}]}'
```

## 📝 İş Akışları

### Sipariş Oluşturma Akışı
1. Admin müşteri seçer
2. Ürünleri ekler
3. Sipariş oluşturulur (POST /api/v1/admin/orders)
4. İsteğe bağlı not eklenir
5. Fiyatlar otomatik hesaplanır

### Teklif Akışı
1. Admin teklif oluşturur (draft)
2. Ürünler ve fiyatlar eklenir
3. Teklif gönderilir (sent)
4. Müşteri kabul ederse siparişe dönüştürülür
5. Her aşamada admin notları eklenir

## ⚠️ Önemli Notlar

- **JWT Token:** Tüm isteklerde gerekli
- **Admin Rolü:** Sadece admin kullanıcılar erişebilir
- **Sayfalama:** Liste endpoint'leri sayfalanmıştır (20 kayıt/sayfa)
- **Filtreleme:** Çoğu liste endpoint'i filtreleme destekler
- **Otomatik Hesaplama:** Fiyatlar ve toplamlar otomatik hesaplanır
- **Polymorphic İlişki:** AdminNote her türlü kayda eklenebilir
- **Quote Validation:** Geçerlilik tarihi gelecekte olmalı
- **Convert Restrictions:** Sadece sent durumundaki teklifler siparişe dönüştürülebilir

## 📚 İlgili Dosyalar

- `app/models/admin_note.rb` - AdminNote model
- `app/models/quote.rb` - Quote model
- `app/models/quote_line.rb` - QuoteLine model
- `app/controllers/api/v1/admin/notes_controller.rb`
- `app/controllers/api/v1/admin/orders_controller.rb`
- `app/controllers/api/v1/admin/quotes_controller.rb`
- `db/migrate/*_create_admin_notes.rb`
- `db/migrate/*_create_quotes.rb`
- `db/migrate/*_create_quote_lines.rb`
