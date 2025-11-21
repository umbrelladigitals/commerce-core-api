# Dealer Dashboard API Dokümantasyonu

## 📊 Genel Bakış

Bayi (Dealer) Dashboard API, bayilerin kendi sipariş geçmişlerini, bakiye hareketlerini, özel iskontolarını ve hesap bilgilerini görüntüleyebilmeleri için tasarlanmış endpoint'ler sağlar.

## 🔐 Yetkilendirme

Tüm endpoint'ler:
- JWT authentication gerektirir (`Authorization: Bearer <token>`)
- Sadece `dealer` role'üne sahip kullanıcılar erişebilir
- Diğer roller (customer, admin, vb.) `403 Forbidden` alır

## 📡 API Endpoints

### 1. Dashboard Overview

**GET** `/api/dealer/dashboard`

Bayinin genel dashboard bilgilerini döner.

**Response:**
```json
{
  "data": {
    "type": "dealer_dashboard",
    "attributes": {
      "dealer_info": {
        "name": "ABC Wholesale",
        "email": "dealer@test.com",
        "role": "dealer"
      },
      "balance": {
        "current": "$500.00",
        "current_cents": 50000,
        "credit_limit": "$1,000.00",
        "credit_limit_cents": 100000,
        "available": "$1,500.00",
        "available_cents": 150000,
        "status": "positive"
      },
      "statistics": {
        "total_orders": 15,
        "total_spent": "$12,345.67",
        "pending_orders": 3,
        "active_discounts_count": 4
      },
      "recent_orders": [...],
      "active_discounts": [...]
    }
  }
}
```

---

### 2. Dealer Orders

**GET** `/api/dealer/orders`

Bayinin tüm siparişlerini listeler.

**Query Parameters:**
- `status` - Sipariş durumu filtresi (paid, shipped, cancelled)
- `start_date` - Başlangıç tarihi (YYYY-MM-DD)
- `end_date` - Bitiş tarihi (YYYY-MM-DD)
- `page` - Sayfa numarası (default: 1)
- `per_page` - Sayfa başına kayıt (default: 20, max: 100)

**Örnek:**
```bash
GET /api/dealer/orders?status=paid&start_date=2024-01-01&page=1&per_page=20
```

**Response:**
```json
{
  "data": [
    {
      "type": "orders",
      "id": "123",
      "attributes": {
        "order_number": "ORD-20240110-000123",
        "status": "paid",
        "total": "$350.00",
        "total_cents": 35000,
        "subtotal": "$300.00",
        "shipping": "$30.00",
        "tax": "$20.00",
        "items_count": 3,
        "paid_at": "2024-01-10T10:30:00Z",
        "created_at": "2024-01-10T10:00:00Z",
        "items": [
          {
            "product_id": 1,
            "product_title": "MacBook Pro",
            "quantity": 1,
            "unit_price": "$2,400.00",
            "total": "$2,400.00"
          }
        ]
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 5,
    "total_count": 95,
    "per_page": 20
  }
}
```

---

### 3. Dealer Discounts

**GET** `/api/dealer/discounts`

Bayiye özel ürün iskontolarını listeler.

**Query Parameters:**
- `active` - Sadece aktif iskontolar (true/false)
- `product_id` - Belirli bir ürün için iskontolar

**Örnek:**
```bash
GET /api/dealer/discounts?active=true
```

**Response:**
```json
{
  "data": [
    {
      "type": "dealer_discounts",
      "id": "1",
      "attributes": {
        "product_id": 1,
        "product_name": "MacBook Pro",
        "product_sku": "MBP-001",
        "discount_percent": 15.0,
        "active": true,
        "created_at": "2024-01-01T00:00:00Z",
        "example_calculation": {
          "original_price": "$2,999.00",
          "discounted_price": "$2,549.15",
          "savings": "$449.85"
        }
      }
    }
  ]
}
```

---

### 4. Dealer Balance

**GET** `/api/dealer/balance`

Bayinin mevcut bakiye bilgilerini döner.

**Response:**
```json
{
  "data": {
    "type": "dealer_balance",
    "id": "1",
    "attributes": {
      "balance": "$500.00",
      "balance_cents": 50000,
      "credit_limit": "$1,000.00",
      "credit_limit_cents": 100000,
      "available_balance": "$1,500.00",
      "available_balance_cents": 150000,
      "currency": "USD",
      "status": "positive",
      "last_transaction_at": "2024-01-10T15:30:00Z"
    }
  }
}
```

---

### 5. Balance Transaction History

**GET** `/api/dealer/balance/history`

Bakiye işlem geçmişini döner.

**Query Parameters:**
- `transaction_type` - İşlem tipi (topup, order_payment, credit, debit, refund)
- `start_date` - Başlangıç tarihi (YYYY-MM-DD)
- `page` - Sayfa numarası (default: 1)
- `per_page` - Sayfa başına kayıt (default: 50, max: 100)

**Örnek:**
```bash
GET /api/dealer/balance/history?transaction_type=topup&page=1&per_page=50
```

**Response:**
```json
{
  "data": [
    {
      "type": "balance_transactions",
      "id": "1",
      "attributes": {
        "transaction_type": "topup",
        "type_label": "Bakiye Yükleme",
        "amount": "$100.00",
        "amount_cents": 10000,
        "positive": true,
        "note": "Manuel bakiye yükleme",
        "order_id": null,
        "order_number": null,
        "created_at": "2024-01-10T15:30:00Z"
      }
    },
    {
      "type": "balance_transactions",
      "id": "2",
      "attributes": {
        "transaction_type": "order_payment",
        "type_label": "Sipariş Ödemesi",
        "amount": "$350.00",
        "amount_cents": 35000,
        "positive": false,
        "note": "Sipariş ödemesi: ORD-20240110-000123",
        "order_id": 123,
        "order_number": "ORD-20240110-000123",
        "created_at": "2024-01-10T14:00:00Z"
      }
    }
  ],
  "meta": {
    "current_page": 1,
    "total_pages": 3,
    "total_count": 45,
    "per_page": 50,
    "current_balance": "$500.00"
  }
}
```

---

### 6. Balance Topup

**POST** `/api/dealer/balance/topup`

Manuel bakiye yükleme yapar.

**Request Body:**
```json
{
  "amount_cents": 10000,
  "note": "Kredi kartı ile yükleme"
}
```

**Parameters:**
- `amount_cents` (required) - Yüklenecek tutar (cent cinsinden, pozitif sayı)
- `note` (optional) - İşlem notu

**Validation:**
- `amount_cents` > 0 olmalı
- Maksimum yükleme: $10,000 (1,000,000 cents)

**Success Response:**
```json
{
  "message": "Bakiye başarıyla yüklendi",
  "data": {
    "type": "dealer_balance",
    "attributes": {
      "balance": "$600.00",
      "balance_cents": 60000,
      "available_balance": "$1,600.00",
      "loaded_amount": "$100.00",
      "loaded_amount_cents": 10000
    }
  }
}
```

**Error Response:**
```json
{
  "error": "Geçersiz tutar",
  "details": "amount_cents pozitif bir sayı olmalıdır"
}
```

---

## 🔄 İşlem Tipleri

### Transaction Types

| Type | Label | Direction | Description |
|------|-------|-----------|-------------|
| `credit` | Kredi Ekleme | + | Genel kredi ekleme |
| `debit` | Borç Düşme | - | Genel borç düşme |
| `topup` | Bakiye Yükleme | + | Manuel bakiye yükleme |
| `order_payment` | Sipariş Ödemesi | - | Sipariş ödemesi |
| `refund` | İade | + | Sipariş iadesi |
| `adjustment` | Düzeltme | +/- | Manuel düzeltme (admin) |

---

## 🧪 Test

### Test Script
```bash
./test_dealer_dashboard.sh
```

### Manuel Test
```bash
# 1. Dealer login
TOKEN=$(curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"dealer@test.com","password":"password123"}}' \
  | jq -r '.token')

# 2. Dashboard
curl -X GET http://localhost:3000/api/dealer/dashboard \
  -H "Authorization: Bearer $TOKEN" | jq '.'

# 3. Balance topup
curl -X POST http://localhost:3000/api/dealer/balance/topup \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount_cents":10000,"note":"Test topup"}' | jq '.'
```

---

## 🏗️ Mimari

### Models

**B2b::DealerBalance**
- Bayinin bakiye ve kredi limit bilgileri
- İlişkiler: `belongs_to :dealer`, `has_many :transactions`
- Metodlar: `add_credit!`, `deduct!`, `topup!`

**B2b::DealerBalanceTransaction**
- Her bakiye değişikliği için kayıt
- İlişkiler: `belongs_to :dealer_balance`, `belongs_to :order`
- Enums: `transaction_type`

**B2b::DealerDiscount**
- Ürün bazlı iskontolar
- İlişkiler: `belongs_to :dealer`, `belongs_to :product`

### Controller

**Api::Dealer::DashboardController**
- `ensure_dealer_role` - Sadece dealer erişimi
- `find_or_create_balance` - Otomatik bakiye oluşturma
- Tüm endpoint'ler current_user üzerinden filtreleme yapar

---

## 🔒 Güvenlik

### Role-Based Access Control
```ruby
before_action :ensure_dealer_role

def ensure_dealer_role
  unless current_user.dealer?
    render json: { error: 'Yetkisiz erişim' }, status: :forbidden
  end
end
```

### Data Isolation
- Tüm sorgular `current_user` üzerinden filtrelenir
- Bayi sadece kendi verilerini görebilir
- Admin endpoint'leri ayrı (`/api/v1/b2b/*`)

---

## 📝 İlişkili Dosyalar

- `app/controllers/api/dealer/dashboard_controller.rb` - Controller
- `app/domains/b2b/dealer_balance.rb` - Bakiye modeli
- `app/domains/b2b/dealer_balance_transaction.rb` - İşlem modeli
- `app/domains/b2b/dealer_discount.rb` - İskonto modeli
- `test_dealer_dashboard.sh` - Test script
- `db/migrate/*_create_dealer_balance_transactions.rb` - Migration

---

## 🚀 Frontend Entegrasyonu

### React Örnek

```jsx
import { useState, useEffect } from 'react';

function DealerDashboard() {
  const [dashboard, setDashboard] = useState(null);
  const token = localStorage.getItem('token');

  useEffect(() => {
    fetch('/api/dealer/dashboard', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
    .then(res => res.json())
    .then(data => setDashboard(data.data.attributes));
  }, []);

  if (!dashboard) return <div>Loading...</div>;

  return (
    <div>
      <h1>Welcome, {dashboard.dealer_info.name}</h1>
      
      <div className="balance">
        <h2>Balance: {dashboard.balance.current}</h2>
        <p>Available: {dashboard.balance.available}</p>
      </div>

      <div className="stats">
        <p>Total Orders: {dashboard.statistics.total_orders}</p>
        <p>Total Spent: {dashboard.statistics.total_spent}</p>
      </div>
    </div>
  );
}
```

### Balance Topup

```jsx
function BalanceTopup() {
  const [amount, setAmount] = useState('');
  const token = localStorage.getItem('token');

  const handleTopup = async () => {
    const response = await fetch('/api/dealer/balance/topup', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        amount_cents: parseInt(amount) * 100,
        note: 'Web interface topup'
      })
    });

    const data = await response.json();
    alert(data.message);
  };

  return (
    <div>
      <input 
        type="number" 
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
        placeholder="Amount in USD"
      />
      <button onClick={handleTopup}>Load Balance</button>
    </div>
  );
}
```

---

## 📊 Database Schema

```sql
CREATE TABLE dealer_balance_transactions (
  id BIGSERIAL PRIMARY KEY,
  dealer_balance_id BIGINT NOT NULL REFERENCES dealer_balances(id),
  transaction_type VARCHAR NOT NULL,
  amount_cents INTEGER NOT NULL DEFAULT 0,
  note TEXT,
  order_id BIGINT REFERENCES orders(id),
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);

CREATE INDEX idx_transactions_type ON dealer_balance_transactions(transaction_type);
CREATE INDEX idx_transactions_date ON dealer_balance_transactions(created_at);
```

---

## 🎯 Kullanım Senaryoları

### 1. Bayi Dashboard Görüntüleme
```
Bayi → Login → Dashboard → Bakiye, siparişler, iskontolar görüntülenir
```

### 2. Bakiye Yükleme
```
Bayi → Topup → amount_cents + note → Transaction kaydı → Bakiye güncellenir
```

### 3. Sipariş Verme (Bakiye ile Ödeme)
```
Bayi → Checkout → DealerBalance.deduct! → Transaction (order_payment) → Sipariş oluşur
```

### 4. İade İşlemi
```
Admin → Refund → DealerBalance.add_credit! → Transaction (refund) → Bakiye iade edilir
```
