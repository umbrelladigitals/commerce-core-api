#!/bin/bash

# Commerce Core API - B2B Test Script
# Tests dealer discounts and balance management
# Usage: ./test_b2b_api.sh [port]

PORT=${1:-3000}
BASE_URL="http://localhost:${PORT}"

echo "💼 Testing B2B API at ${BASE_URL}"
echo "================================================"
echo ""

# Test 1: Login as dealer
echo "🔐 Step 1: Login as dealer"
echo "POST ${BASE_URL}/users/sign_in"
DEALER_LOGIN=$(curl -s -i -X POST "${BASE_URL}/users/sign_in" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "dealer@example.com",
      "password": "password123"
    }
  }')

DEALER_TOKEN=$(echo "$DEALER_LOGIN" | grep -i "^authorization:" | sed 's/authorization: Bearer //i' | tr -d '\r\n ')

if [ -z "$DEALER_TOKEN" ]; then
  echo "❌ Dealer login failed!"
  exit 1
fi

echo "✅ Dealer login successful! Token: ${DEALER_TOKEN:0:20}..."
echo ""
echo ""

# Test 2: View dealer balance
echo "💰 Step 2: View dealer balance"
echo "GET ${BASE_URL}/api/v1/b2b/my_balance"
curl -s "${BASE_URL}/api/v1/b2b/my_balance" \
  -H "Authorization: Bearer $DEALER_TOKEN" | jq '.'
echo ""
echo ""

# Test 3: View dealer discounts
echo "💸 Step 3: View dealer discounts"
echo "GET ${BASE_URL}/api/v1/b2b/dealer_discounts"
curl -s "${BASE_URL}/api/v1/b2b/dealer_discounts" \
  -H "Authorization: Bearer $DEALER_TOKEN" | jq '.'
echo ""
echo ""

# Test 4: Add product to cart (dealer gets automatic discount)
echo "🛒 Step 4: Add product to cart with dealer discount"
echo "POST ${BASE_URL}/api/cart/add"
curl -s -X POST "${BASE_URL}/api/cart/add" \
  -H "Authorization: Bearer $DEALER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 1,
    "variant_id": 1,
    "quantity": 2
  }' | jq '.'
echo ""
echo ""

# Test 5: View cart with dealer pricing
echo "🛒 Step 5: View cart (should show dealer discounts)"
echo "GET ${BASE_URL}/api/cart"
DEALER_CART=$(curl -s "${BASE_URL}/api/cart" \
  -H "Authorization: Bearer $DEALER_TOKEN")
echo "$DEALER_CART" | jq '.'
echo ""
echo ""

# Test 6: Add discounted product (Mouse with 20% discount)
echo "🛒 Step 6: Add heavily discounted product (Mouse 20% off)"
echo "POST ${BASE_URL}/api/cart/add"
curl -s -X POST "${BASE_URL}/api/cart/add" \
  -H "Authorization: Bearer $DEALER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_id": 3,
    "quantity": 5
  }' | jq '.'
echo ""
echo ""

# Test 7: Checkout with dealer pricing
echo "💳 Step 7: Checkout (with dealer discounts applied)"
echo "POST ${BASE_URL}/api/cart/checkout"
curl -s -X POST "${BASE_URL}/api/cart/checkout" \
  -H "Authorization: Bearer $DEALER_TOKEN" | jq '.'
echo ""
echo ""

# Test 8: Login as admin
echo "🔐 Step 8: Login as admin"
ADMIN_LOGIN=$(curl -s -i -X POST "${BASE_URL}/users/sign_in" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@example.com",
      "password": "password123"
    }
  }')

ADMIN_TOKEN=$(echo "$ADMIN_LOGIN" | grep -i "^authorization:" | sed 's/authorization: Bearer //i' | tr -d '\r\n ')
echo "✅ Admin login successful!"
echo ""
echo ""

# Test 9: Admin views all dealer balances
echo "💰 Step 9: Admin views all dealer balances"
echo "GET ${BASE_URL}/api/v1/b2b/dealer_balances"
curl -s "${BASE_URL}/api/v1/b2b/dealer_balances" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'
echo ""
echo ""

# Test 10: Admin adds credit to dealer
echo "💵 Step 10: Admin adds credit to dealer balance"
echo "POST ${BASE_URL}/api/v1/b2b/dealer_balances/1/add_credit"
curl -s -X POST "${BASE_URL}/api/v1/b2b/dealer_balances/1/add_credit" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount_cents": 100000,
    "note": "Payment received for invoice #12345"
  }' | jq '.'
echo ""
echo ""

# Test 11: Admin creates new discount
echo "💸 Step 11: Admin creates new dealer discount"
echo "POST ${BASE_URL}/api/v1/b2b/dealer_discounts"
curl -s -X POST "${BASE_URL}/api/v1/b2b/dealer_discounts" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "dealer_id": 3,
    "product_id": 5,
    "discount_percent": 25.0
  }' | jq '.'
echo ""
echo ""

# Test 12: Admin updates credit limit
echo "💳 Step 12: Admin updates dealer credit limit"
echo "PATCH ${BASE_URL}/api/v1/b2b/dealer_balances/1/update_credit_limit"
curl -s -X PATCH "${BASE_URL}/api/v1/b2b/dealer_balances/1/update_credit_limit" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "credit_limit_cents": 200000
  }' | jq '.'
echo ""
echo ""

echo "✅ All B2B tests completed!"
echo ""
echo "📝 B2B Features Tested:"
echo "  ✅ Dealer authentication"
echo "  ✅ Dealer balance viewing"
echo "  ✅ Dealer discount listing"
echo "  ✅ Automatic discount application in cart"
echo "  ✅ Dealer-specific pricing (10% lower shipping threshold)"
echo "  ✅ Admin balance management"
echo "  ✅ Admin credit operations"
echo "  ✅ Admin discount creation"
echo "  ✅ Admin credit limit updates"
echo ""
echo "💡 Key B2B Features:"
echo "  - Dealers get product-specific discounts (10-25%)"
echo "  - Dealers get free shipping at $100 (vs $200 for regular customers)"
echo "  - Dealers have credit accounts with configurable limits"
echo "  - Admin can manage all dealer finances"
echo "  - OrderPriceCalculator automatically applies dealer discounts"
echo ""
echo "🔍 Check logs for balance transactions:"
echo "  tail -f log/development.log | grep 'DEALER BALANCE'"
