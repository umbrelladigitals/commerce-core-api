# PayTR Ödeme Entegrasyonu

Bu proje PayTR ödeme sağlayıcısı ile entegre edilmiştir.

## 🔧 Kurulum

### Environment Variables

`.env` dosyanıza aşağıdaki değişkenleri ekleyin:

```bash
# PayTR Credentials
PAYTR_MERCHANT_ID=your_merchant_id_here
PAYTR_MERCHANT_KEY=your_merchant_key_here
PAYTR_MERCHANT_SALT=your_merchant_salt_here

# PayTR Callback URL (production için gerçek domain kullanın)
PAYTR_CALLBACK_URL=https://yourdomain.com/api/payment
```

Bu bilgileri PayTR merchant panelinden alabilirsiniz.

## 📡 API Endpoints

### 1. Checkout - PayTR Token Alma

```bash
POST /api/cart/checkout
Authorization: Bearer {token}
```

**Response:**
```json
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
      "iframe_url": "https://www.paytr.com/odeme/guvenli/AbCdEf123456..."
    }
  },
  "meta": {
    "next_step": "Kullanıcıyı iframe_url'ye yönlendirin veya iframe içinde gösterin"
  }
}
```

### 2. PayTR Callback (Sunucu-Sunucu)

```bash
POST /api/payment/paytr/callback
```

Bu endpoint PayTR tarafından otomatik olarak çağrılır. Manuel test için kullanılmaz.

**Parameters:**
- `merchant_oid`: Sipariş numarası (ORDER-123 formatında)
- `status`: Ödeme durumu (success/failed)
- `total_amount`: Ödenen tutar (kuruş cinsinden)
- `hash`: İmza doğrulama

### 3. Başarılı Ödeme Redirect

```bash
GET /api/payment/paytr/success?merchant_oid=ORDER-123
```

Kullanıcı başarılı ödeme sonrası bu URL'ye yönlendirilir.

### 4. Başarısız Ödeme Redirect

```bash
GET /api/payment/paytr/fail?merchant_oid=ORDER-123&failed_reason_code=XXX
```

Kullanıcı başarısız ödeme sonrası bu URL'ye yönlendirilir.

## 🔄 Akış Diyagramı

```
1. Kullanıcı → POST /api/cart/checkout
   ↓
2. Backend → PayTR API → Token oluştur
   ↓
3. Frontend ← paytr_token + iframe_url
   ↓
4. Frontend → Kullanıcıyı iframe_url'ye yönlendir veya iframe'de göster
   ↓
5. Kullanıcı → PayTR'da ödeme yapar
   ↓
6. PayTR → POST /api/payment/paytr/callback (sunucu-sunucu)
   ↓
7. Backend → İmza doğrula
   ↓
8. Backend → Sipariş durumunu güncelle (cart → paid)
   ↓
9. Backend → OrderConfirmationJob tetikle (e-posta gönder)
   ↓
10. PayTR → Kullanıcıyı success/fail URL'sine yönlendir
```

## 🧪 Test

Test script'ini çalıştırın:

```bash
chmod +x test_paytr_api.sh
./test_paytr_api.sh
```

### Manuel Test Adımları

1. **Login**
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"dealer@test.com","password":"password123"}}'
```

2. **Sepete Ürün Ekle**
```bash
curl -X POST http://localhost:3000/api/cart/add \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"quantity":2}'
```

3. **Checkout**
```bash
curl -X POST http://localhost:3000/api/cart/checkout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response'dan `iframe_url` alın ve tarayıcıda açın.

## 💻 Frontend Entegrasyonu

### React Örneği

```jsx
import React, { useState } from 'react';

function Checkout() {
  const [iframeUrl, setIframeUrl] = useState(null);

  const handleCheckout = async () => {
    const response = await fetch('/api/cart/checkout', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('token')}`,
        'Content-Type': 'application/json'
      }
    });

    const data = await response.json();
    
    if (data.data.attributes.iframe_url) {
      setIframeUrl(data.data.attributes.iframe_url);
    }
  };

  return (
    <div>
      <button onClick={handleCheckout}>Ödemeye Geç</button>
      
      {iframeUrl && (
        <iframe 
          src={iframeUrl} 
          width="100%" 
          height="600px"
          frameBorder="0"
        />
      )}
    </div>
  );
}
```

### Alternatif: Yeni Sekmede Açma

```javascript
const handleCheckout = async () => {
  const response = await fetch('/api/cart/checkout', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${localStorage.getItem('token')}`,
      'Content-Type': 'application/json'
    }
  });

  const data = await response.json();
  
  if (data.data.attributes.iframe_url) {
    window.location.href = data.data.attributes.iframe_url;
  }
};
```

## 🔒 Güvenlik

### İmza Doğrulama

PayTR callback'lerde gelen `hash` parametresi şu şekilde doğrulanır:

```ruby
hash_str = "#{merchant_oid}#{merchant_salt}#{status}#{total_amount}"
expected_hash = Base64.strict_encode64(
  OpenSSL::HMAC.digest("sha256", merchant_key, hash_str)
)
```

### CSRF Koruması

PayTR callback endpoint'leri için CSRF koruması devre dışı bırakılmıştır:

```ruby
skip_before_action :verify_authenticity_token, only: [:paytr_callback]
```

## 📝 Notlar

- PayTR test ortamı için test merchant bilgilerini kullanın
- Production'a geçmeden önce gerçek merchant bilgilerinizi girin
- Callback URL'leri PayTR panelinde doğru şekilde yapılandırın
- SSL sertifikası zorunludur (HTTPS)
- PayTR callback'i birden fazla kez gönderebilir, idempotent olmalı

## 🐛 Sorun Giderme

### Token oluşturulamıyor

- Environment variables'ları kontrol edin
- PayTR merchant bilgilerinin doğru olduğundan emin olun
- Log dosyalarını kontrol edin: `log/development.log`

### Callback gelmiyor

- PayTR panelinden callback URL'ini kontrol edin
- Sunucunun internetten erişilebilir olduğundan emin olun
- Firewall kurallarını kontrol edin
- ngrok gibi bir tunnel kullanabilirsiniz (development için)

### Sipariş durumu güncellenmiyor

- Callback'te imza doğrulama hatası olabilir
- Log dosyalarını kontrol edin
- PayTR'dan gelen parametreleri loglayın

## 📚 Kaynaklar

- [PayTR Dokümantasyonu](https://www.paytr.com/magaza/api-entegrasyonu)
- [PayTR Test Ortamı](https://www.paytr.com/magaza/test-bilgileri)
- [PayTR Destek](https://www.paytr.com/iletisim)
