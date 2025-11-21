#!/bin/bash

# Test Checkout Akışı

echo "===== CHECKOUT SERVİSİ TEST ====="
echo ""

# 1. Dealer kullanıcısı oluştur
echo "1. Dealer kullanıcısı oluşturuluyor..."
curl -s -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test_dealer@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "first_name": "Test",
      "last_name": "Dealer",
      "role": "dealer"
    }
  }' | jq '.'

echo ""
echo "2. Dealer giriş yapıyor..."
TOKEN=$(curl -s -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "dealer@example.com",
      "password": "password123"
    }
  }' | jq -r '.token')

echo "Token: $TOKEN"
echo ""

# 3. Sepete ürün ekle
echo "3. Sepete ürün ekleniyor..."
curl -s -X POST http://localhost:3000/api/cart/add \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "quantity": 2
  }' | jq '.'

echo ""

# 4. Sepeti görüntüle
echo "4. Sepet görüntüleniyor..."
curl -s -X GET http://localhost:3000/api/cart \
  -H "Authorization: Bearer $TOKEN" | jq '.'

echo ""

# 5. Checkout önizleme
echo "5. Checkout önizlemesi..."
curl -s -X GET http://localhost:3000/api/cart/checkout/preview \
  -H "Authorization: Bearer $TOKEN" | jq '.'

echo ""

# 6. Checkout - Dealer bakiyesi ile ödeme
echo "6. Checkout - Dealer bakiyesi ile ödeme..."
curl -s -X POST http://localhost:3000/api/cart/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_method": "dealer_balance",
    "shipping_address": {
      "name": "Test Dealer",
      "phone": "+905551234567",
      "address_line1": "Test Mahallesi, Test Sokak No:1",
      "city": "İstanbul",
      "postal_code": "34000",
      "country": "TR"
    },
    "notes": "Test siparişi"
  }' | jq '.'

echo ""
echo "===== TEST TAMAMLANDI ====="
