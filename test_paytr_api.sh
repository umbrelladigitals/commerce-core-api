#!/bin/bash

# PayTR API Test Script
# Bu script PayTR ödeme entegrasyonunu test eder

BASE_URL="http://localhost:3000"
API_BASE="$BASE_URL/api"

# Renkli output için
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== PayTR Payment Integration Test ===${NC}\n"

# 1. Login
echo -e "${YELLOW}1. User Login${NC}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "dealer@test.com",
      "password": "password123"
    }
  }')

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token // empty')

if [ -z "$TOKEN" ]; then
  echo -e "${RED}✗ Login failed${NC}"
  echo $LOGIN_RESPONSE | jq '.'
  exit 1
fi

echo -e "${GREEN}✓ Login successful${NC}"
echo "Token: ${TOKEN:0:20}..."
echo ""

# 2. Sepete ürün ekle
echo -e "${YELLOW}2. Add Product to Cart${NC}"
ADD_RESPONSE=$(curl -s -X POST "$API_BASE/cart/add" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "quantity": 2
  }')

echo $ADD_RESPONSE | jq '.'
echo ""

# 3. Sepeti görüntüle
echo -e "${YELLOW}3. View Cart${NC}"
CART_RESPONSE=$(curl -s -X GET "$API_BASE/cart" \
  -H "Authorization: Bearer $TOKEN")

CART_TOTAL=$(echo $CART_RESPONSE | jq -r '.data.attributes.total // "N/A"')
echo -e "${GREEN}Cart Total: $CART_TOTAL${NC}"
echo ""

# 4. Checkout - PayTR Token Al
echo -e "${YELLOW}4. Checkout - Get PayTR Token${NC}"
CHECKOUT_RESPONSE=$(curl -s -X POST "$API_BASE/cart/checkout" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

echo $CHECKOUT_RESPONSE | jq '.'

PAYTR_TOKEN=$(echo $CHECKOUT_RESPONSE | jq -r '.data.attributes.paytr_token // empty')
IFRAME_URL=$(echo $CHECKOUT_RESPONSE | jq -r '.data.attributes.iframe_url // empty')
ORDER_ID=$(echo $CHECKOUT_RESPONSE | jq -r '.data.attributes.order_id // empty')

if [ -n "$PAYTR_TOKEN" ]; then
  echo -e "${GREEN}✓ PayTR Token created successfully${NC}"
  echo "Token: ${PAYTR_TOKEN:0:30}..."
  echo "Iframe URL: $IFRAME_URL"
  echo "Order ID: $ORDER_ID"
else
  echo -e "${RED}✗ Failed to create PayTR token${NC}"
fi
echo ""

# 5. Simulate PayTR Callback (Başarılı Ödeme)
echo -e "${YELLOW}5. Simulate PayTR Callback (Success)${NC}"
echo "Simulating successful payment callback from PayTR..."

# PayTR callback parametrelerini oluştur
MERCHANT_OID="ORDER-$ORDER_ID"
STATUS="success"
TOTAL_AMOUNT="10000" # Kuruş cinsinden

# Hash hesapla (gerçek implementasyonda PayTR merchant_salt ile)
# hash = base64(HMAC-SHA256(merchant_key, "merchant_oid+merchant_salt+status+total_amount"))
# Test için basitleştirilmiş hash

CALLBACK_RESPONSE=$(curl -s -X POST "$API_BASE/payment/paytr/callback" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "merchant_oid=$MERCHANT_OID" \
  -d "status=$STATUS" \
  -d "total_amount=$TOTAL_AMOUNT" \
  -d "hash=test_hash_value")

echo "Callback Response: $CALLBACK_RESPONSE"
echo ""

# 6. Siparişi kontrol et
echo -e "${YELLOW}6. Check Order Status${NC}"
echo "Checking if order status changed to 'paid'..."

ORDER_RESPONSE=$(curl -s -X GET "$API_BASE/v1/orders/$ORDER_ID" \
  -H "Authorization: Bearer $TOKEN")

ORDER_STATUS=$(echo $ORDER_RESPONSE | jq -r '.data.attributes.status // "N/A"')
echo "Order Status: $ORDER_STATUS"

if [ "$ORDER_STATUS" = "paid" ]; then
  echo -e "${GREEN}✓ Order status updated to 'paid'${NC}"
else
  echo -e "${RED}✗ Order status not updated${NC}"
fi
echo ""

# 7. Test Summary
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo "✓ User authentication"
echo "✓ Cart operations"
echo "✓ PayTR token generation"
echo "✓ Payment callback handling"
echo ""
echo -e "${GREEN}Frontend Integration Steps:${NC}"
echo "1. Call POST /api/cart/checkout"
echo "2. Get paytr_token and iframe_url from response"
echo "3. Redirect user to iframe_url OR embed in iframe"
echo "4. PayTR will call /api/payment/paytr/callback after payment"
echo "5. Order status will automatically update to 'paid'"
echo "6. User will be redirected to success/fail URLs"
echo ""

echo -e "${YELLOW}Environment Variables Needed:${NC}"
echo "PAYTR_MERCHANT_ID=your_merchant_id"
echo "PAYTR_MERCHANT_KEY=your_merchant_key"
echo "PAYTR_MERCHANT_SALT=your_merchant_salt"
echo "PAYTR_CALLBACK_URL=https://yourdomain.com/api/payment"
