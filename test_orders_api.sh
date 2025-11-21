#!/bin/bash

# Commerce Core API - Orders & Cart Test Script
# Usage: ./test_orders_api.sh [port]

PORT=${1:-3000}
BASE_URL="http://localhost:${PORT}"

echo "🛒 Testing Orders & Cart API at ${BASE_URL}"
echo "================================================"
echo ""

# Login and get token
echo "🔐 Step 1: Login as customer"
echo "POST ${BASE_URL}/users/sign_in"
LOGIN_RESPONSE=$(curl -s -i -X POST "${BASE_URL}/users/sign_in" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "customer@example.com",
      "password": "password123"
    }
  }')

# Extract token from Authorization header
TOKEN=$(echo "$LOGIN_RESPONSE" | grep -i "^authorization:" | sed 's/authorization: Bearer //i' | tr -d '\r\n ')

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed! Could not get token."
  echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Login successful! Token: ${TOKEN:0:20}..."
echo ""
echo ""

# Test 1: View cart
echo "🛒 Step 2: View current cart"
echo "GET ${BASE_URL}/api/cart"
curl -s "${BASE_URL}/api/cart" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
echo ""
echo ""

# Test 2: Add product to cart (with variant)
echo "➕ Step 3: Add MacBook Pro to cart (with variant)"
echo "POST ${BASE_URL}/api/cart/add"
curl -s -X POST "${BASE_URL}/api/cart/add" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "variant_id": 1,
    "quantity": 1,
    "note": "Hediye paketi istiyorum"
  }' | jq '.'
echo ""
echo ""

# Test 3: Add product without variant
echo "➕ Step 4: Add mouse to cart (without variant)"
echo "POST ${BASE_URL}/api/cart/add"
curl -s -X POST "${BASE_URL}/api/cart/add" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 3,
    "quantity": 2
  }' | jq '.'
echo ""
echo ""

# Test 4: View updated cart
echo "🛒 Step 5: View updated cart"
echo "GET ${BASE_URL}/api/cart"
CART_DATA=$(curl -s "${BASE_URL}/api/cart" \
  -H "Authorization: Bearer $TOKEN")
echo "$CART_DATA" | jq '.'

# Extract first order line id for update test
ORDER_LINE_ID=$(echo "$CART_DATA" | jq -r '.data.included[0].id')
echo ""
echo "First order line ID: $ORDER_LINE_ID"
echo ""
echo ""

# Test 5: Update item quantity
if [ ! -z "$ORDER_LINE_ID" ]; then
  echo "✏️  Step 6: Update item quantity"
  echo "PATCH ${BASE_URL}/api/cart/items/${ORDER_LINE_ID}"
  curl -s -X PATCH "${BASE_URL}/api/cart/items/${ORDER_LINE_ID}" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "quantity": 2
    }' | jq '.'
  echo ""
  echo ""
fi

# Test 6: Checkout
echo "💳 Step 7: Start checkout process"
echo "POST ${BASE_URL}/api/cart/checkout"
CHECKOUT_RESPONSE=$(curl -s -X POST "${BASE_URL}/api/cart/checkout" \
  -H "Authorization: Bearer $TOKEN")
echo "$CHECKOUT_RESPONSE" | jq '.'

# Extract order id
ORDER_ID=$(echo "$CHECKOUT_RESPONSE" | jq -r '.data.attributes.order_id')
echo ""
echo "Order ID: $ORDER_ID"
echo ""
echo ""

# Test 7: Confirm payment
if [ ! -z "$ORDER_ID" ] && [ "$ORDER_ID" != "null" ]; then
  echo "✅ Step 8: Confirm payment"
  echo "POST ${BASE_URL}/api/payment/confirm"
  curl -s -X POST "${BASE_URL}/api/payment/confirm" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"order_id\": $ORDER_ID
    }" | jq '.'
  echo ""
  echo ""
  
  echo "📧 Check Sidekiq logs for confirmation email!"
  echo "tail -f log/development.log | grep 'SIPARIŞ ONAYI'"
fi

echo ""
echo "✅ All cart & orders tests completed!"
echo ""
echo "📝 Notes:"
echo "  - Cart is automatically created for logged-in users"
echo "  - Same product+variant creates new line or updates existing"
echo "  - OrderPriceCalculator runs automatically on changes"
echo "  - Free shipping for orders over $200"
echo "  - 18% tax (KDV) is calculated on subtotal + shipping"
echo "  - OrderConfirmationJob sends email via Sidekiq"
echo ""
echo "🔍 Next steps:"
echo "  - Check logs: tail -f log/development.log"
echo "  - Check Sidekiq: http://localhost:3000/sidekiq"
echo "  - View all orders in database: rails console"
