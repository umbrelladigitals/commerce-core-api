# PayTR Entegrasyonu - Hızlı Başlangıç

## 🚀 5 Dakikada Kurulum

### 1. Environment Variables (.env)
```bash
PAYTR_MERCHANT_ID=123456
PAYTR_MERCHANT_KEY=abc123def456
PAYTR_MERCHANT_SALT=xyz789
PAYTR_CALLBACK_URL=https://yourdomain.com/api/payment
```

### 2. Sunucuyu Başlat
```bash
rails s
```

### 3. Frontend Entegrasyonu

#### React/JavaScript Örneği
```javascript
// Checkout butonuna tıklandığında
async function handleCheckout() {
  try {
    const response = await fetch('/api/cart/checkout', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    const data = await response.json();
    
    // PayTR iframe URL'sine yönlendir
    if (data.data.attributes.iframe_url) {
      window.location.href = data.data.attributes.iframe_url;
      // VEYA iframe içinde göster:
      // setIframeUrl(data.data.attributes.iframe_url);
    }
  } catch (error) {
    console.error('Checkout error:', error);
  }
}
```

#### HTML Iframe Örneği
```html
<button onclick="checkout()">Ödemeye Geç</button>

<div id="payment-container" style="display: none;">
  <iframe id="paytr-iframe" width="100%" height="600"></iframe>
</div>

<script>
async function checkout() {
  const response = await fetch('/api/cart/checkout', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer ' + localStorage.getItem('token')
    }
  });
  
  const data = await response.json();
  
  document.getElementById('paytr-iframe').src = data.data.attributes.iframe_url;
  document.getElementById('payment-container').style.display = 'block';
}
</script>
```

## 📱 API Kullanımı

### Checkout Request
```bash
curl -X POST http://localhost:3000/api/cart/checkout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Response
```json
{
  "data": {
    "attributes": {
      "order_id": 123,
      "paytr_token": "...",
      "iframe_url": "https://www.paytr.com/odeme/guvenli/..."
    }
  }
}
```

## 🔄 Ödeme Akışı (Basit)

1. **Frontend:** POST `/api/cart/checkout` → PayTR token al
2. **Frontend:** Kullanıcıyı `iframe_url`'ye yönlendir
3. **Kullanıcı:** PayTR'da ödeme yapar
4. **PayTR:** Backend'e callback gönderir
5. **Backend:** Sipariş durumunu `paid` yapar
6. **Backend:** Email gönderir
7. **PayTR:** Kullanıcıyı success/fail URL'sine yönlendirir

## 🧪 Test

```bash
# Test script
./test_paytr_api.sh

# Manuel test için
# 1. Login
TOKEN=$(curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"dealer@test.com","password":"password123"}}' \
  | jq -r '.token')

# 2. Sepete ürün ekle
curl -X POST http://localhost:3000/api/cart/add \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id":1,"quantity":2}'

# 3. Checkout
curl -X POST http://localhost:3000/api/cart/checkout \
  -H "Authorization: Bearer $TOKEN"
```

## ⚠️ Önemli Notlar

- **SSL Zorunlu:** PayTR sadece HTTPS callback'leri kabul eder
- **Development:** ngrok kullanarak test edebilirsiniz
- **Callback:** PayTR'a her zaman "OK" dönülmeli
- **Idempotent:** Callback birden fazla gelebilir

## 🐛 Sorun Giderme

### Token oluşturulamıyor
```bash
# ENV variables kontrolü
echo $PAYTR_MERCHANT_ID
echo $PAYTR_MERCHANT_KEY
```

### Callback gelmiyor
```bash
# ngrok ile test
ngrok http 3000
# URL'yi .env dosyasına ekle
```

### Log kontrolü
```bash
tail -f log/development.log | grep -i paytr
```

## 📞 Destek

- Dokümantasyon: `PAYTR_INTEGRATION.md`
- Implementasyon Detayları: `PAYTR_IMPLEMENTATION_SUMMARY.md`
- PayTR Destek: https://www.paytr.com/iletisim
