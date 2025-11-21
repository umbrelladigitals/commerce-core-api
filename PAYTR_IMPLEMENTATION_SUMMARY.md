# PayTR Ödeme Entegrasyonu - Implementasyon Özeti

## 📁 Oluşturulan Dosyalar

### 1. Service Layer
- **`app/services/paytr_service.rb`** (172 satır)
  - PayTR API ile iletişim
  - Token oluşturma (HMAC-SHA256)
  - Callback imza doğrulama
  - Sepet formatı oluşturma

### 2. Controller Updates
- **`app/controllers/api/v1/payment_controller.rb`** (güncellenmiş)
  - `paytr_callback` - PayTR'dan sunucu-sunucu bildirim
  - `paytr_success` - Başarılı ödeme redirect
  - `paytr_fail` - Başarısız ödeme redirect
  - `handle_paytr_success` - Sipariş durumu güncelleme
  - `handle_paytr_failure` - Stok iade

- **`app/controllers/api/v1/cart_controller.rb`** (güncellenmiş)
  - `checkout` metodu PayTR entegrasyonu ile güncellendi
  - PayTR token oluşturma
  - iframe_url dönüşü

### 3. Routes
- **`config/routes.rb`** (güncellenmiş)
  ```ruby
  POST /api/payment/paytr/callback
  GET  /api/payment/paytr/success
  GET  /api/payment/paytr/fail
  ```

### 4. Documentation
- **`PAYTR_INTEGRATION.md`** - Tam entegrasyon dokümantasyonu
- **`test_paytr_api.sh`** - Otomatik test script'i
- **`.env.example`** - Environment variables örneği

## 🔄 Ödeme Akışı

```
┌─────────────┐
│   Frontend  │
└──────┬──────┘
       │ 1. POST /api/cart/checkout
       ↓
┌─────────────┐
│   Backend   │
└──────┬──────┘
       │ 2. PaytrService.create_payment_token
       ↓
┌─────────────┐
│  PayTR API  │
└──────┬──────┘
       │ 3. Return token
       ↓
┌─────────────┐
│   Backend   │
└──────┬──────┘
       │ 4. Return {token, iframe_url}
       ↓
┌─────────────┐
│   Frontend  │───────────────┐
└─────────────┘               │
                              │ 5. Redirect or show iframe
                              ↓
                        ┌─────────────┐
                        │ PayTR Page  │
                        └──────┬──────┘
                               │ 6. User pays
                               ↓
                        ┌─────────────┐
                        │    PayTR    │
                        └──────┬──────┘
                               │ 7. POST /api/payment/paytr/callback
                               ↓
                        ┌─────────────┐
                        │   Backend   │
                        └──────┬──────┘
                               │ 8. Verify signature
                               │ 9. Update order: cart → paid
                               │ 10. Trigger OrderConfirmationJob
                               ↓
                        ┌─────────────┐
                        │    Email    │
                        └─────────────┘
```

## 🔐 Güvenlik Özellikleri

### İmza Doğrulama (HMAC-SHA256)

**Token Oluşturma:**
```ruby
hash_str = "#{merchant_id}#{user_ip}#{merchant_oid}#{email}#{payment_amount}#{user_basket}no_installment0#{ok_url}#{fail_url}"
hash_with_salt = hash_str + merchant_salt
token = Base64.strict_encode64(
  OpenSSL::HMAC.digest("sha256", merchant_key, hash_with_salt)
)
```

**Callback Doğrulama:**
```ruby
hash_str = "#{merchant_oid}#{merchant_salt}#{status}#{total_amount}"
expected_hash = Base64.strict_encode64(
  OpenSSL::HMAC.digest("sha256", merchant_key, hash_str)
)
```

### CSRF Protection
- Callback endpoint'leri için CSRF koruması devre dışı
- `skip_before_action :verify_authenticity_token`

## 📊 API Endpoints

### 1. Checkout (Frontend → Backend)
```http
POST /api/cart/checkout
Authorization: Bearer {token}
Content-Type: application/json

Response:
{
  "message": "Ödeme işlemi başlatıldı",
  "data": {
    "type": "checkout",
    "attributes": {
      "order_id": 123,
      "order_number": "ORD-20231010-000123",
      "total": "$100.00",
      "currency": "USD",
      "payment_provider": "paytr",
      "paytr_token": "AbCdEf123456...",
      "iframe_url": "https://www.paytr.com/odeme/guvenli/..."
    }
  }
}
```

### 2. Callback (PayTR → Backend)
```http
POST /api/payment/paytr/callback
Content-Type: application/x-www-form-urlencoded

merchant_oid=ORDER-123
status=success
total_amount=10000
hash=AbCdEf123456...

Response: "OK"
```

### 3. Success Redirect (PayTR → Frontend)
```http
GET /api/payment/paytr/success?merchant_oid=ORDER-123

Response:
{
  "success": true,
  "message": "Ödemeniz başarıyla tamamlandı",
  "data": {
    "merchant_oid": "ORDER-123"
  }
}
```

### 4. Fail Redirect (PayTR → Frontend)
```http
GET /api/payment/paytr/fail?merchant_oid=ORDER-123&failed_reason_code=XXX

Response:
{
  "success": false,
  "message": "Ödeme işlemi başarısız oldu",
  "data": {
    "merchant_oid": "ORDER-123",
    "reason_code": "XXX",
    "reason_message": "..."
  }
}
```

## ⚙️ Environment Variables

```bash
PAYTR_MERCHANT_ID=123456
PAYTR_MERCHANT_KEY=abc123def456
PAYTR_MERCHANT_SALT=xyz789
PAYTR_CALLBACK_URL=https://yourdomain.com/api/payment
```

## 🧪 Test

```bash
# Test script'ini çalıştır
chmod +x test_paytr_api.sh
./test_paytr_api.sh

# Manuel test
curl -X POST http://localhost:3000/api/cart/checkout \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

## ✅ Acceptance Criteria

- [x] `/api/cart/checkout` çağrısı PayTR token döner
- [x] `iframe_url` frontend'e iletilir
- [x] PayTR callback geldiğinde sipariş durumu `paid` olur
- [x] `OrderConfirmationJob` tetiklenir
- [x] İmza doğrulama çalışır
- [x] Stok iade mekanizması (başarısız ödemelerde)

## 📝 Notlar

### Idempotency
- Callback birden fazla kez gelebilir
- `mark_as_paid!` metodu zaten `cart?` kontrolü yapıyor
- `handle_paytr_success` içinde `return if order.paid?` kontrolü var

### Error Handling
- Tüm hatalar loglanıyor
- PayTR'a her zaman "OK" dönülüyor (tekrar deneme için)
- Frontend'e anlamlı hata mesajları

### Production Checklist
- [ ] PayTR merchant bilgilerini production'a ekle
- [ ] SSL sertifikası aktif
- [ ] Callback URL'leri PayTR panelinde tanımla
- [ ] Email bildirimleri test et
- [ ] Rate limiting ekle (opsiyonel)
- [ ] Webhook retry mekanizması test et

## 🔍 Debugging

### Log Kontrolü
```bash
tail -f log/development.log | grep -i paytr
```

### Callback Test (ngrok)
```bash
# Terminal 1: ngrok başlat
ngrok http 3000

# Terminal 2: .env dosyasını güncelle
PAYTR_CALLBACK_URL=https://abc123.ngrok.io/api/payment

# Terminal 3: Rails server
rails s
```

### Common Issues

**Token oluşturulamıyor:**
- ENV variables kontrolü
- Merchant bilgileri doğru mu?

**Callback gelmiyor:**
- PayTR panelinde URL doğru mu?
- Sunucu erişilebilir mi?
- SSL sertifikası geçerli mi?

**Sipariş güncellenmiyor:**
- İmza doğrulama hatası?
- Log dosyalarını kontrol et
- Callback parametrelerini loga yaz

## 📚 İlgili Dosyalar

- `app/domains/orders/order.rb` - `mark_as_paid!` metodu
- `app/jobs/orders/order_confirmation_job.rb` - Email gönderimi
- `app/domains/orders/order_line.rb` - `reserve_stock!`, `restore_stock!`

## 🎯 Sonraki Adımlar

1. Frontend entegrasyonu (React/Vue/Angular)
2. Email template'leri güzelleştirme
3. Admin panelinde ödeme raporları
4. PayTR test ortamında test
5. Production deployment
