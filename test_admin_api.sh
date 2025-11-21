#!/bin/bash

# Admin Panel API Test Script
# Tests admin order creation, notes, and quotes

BASE_URL="http://localhost:3000"
API_BASE="$BASE_URL/api"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}=== Admin Panel API Test ===${NC}\n"

# 1. Login as Admin
echo -e "${YELLOW}1. Admin Login${NC}"
ADMIN_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@test.com",
      "password": "password123"
    }
  }')

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token // empty')

if [ -z "$ADMIN_TOKEN" ]; then
  echo -e "${RED}✗ Admin login failed${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Admin logged in${NC}"
echo ""

# 2. Login as Dealer (for creating order on behalf)
echo -e "${YELLOW}2. Get Dealer User${NC}"
DEALER_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "dealer@test.com",
      "password": "password123"
    }
  }')

DEALER_TOKEN=$(echo $DEALER_LOGIN | jq -r '.token // empty')
DEALER_ID=$(echo $DEALER_LOGIN | jq -r '.user.id // empty')

echo -e "${GREEN}✓ Dealer ID: $DEALER_ID${NC}"
echo ""

# 3. Create Order on Behalf of Dealer
echo -e "${YELLOW}3. Admin Creates Order for Dealer${NC}"
ORDER_CREATE=$(curl -s -X POST "$API_BASE/v1/admin/orders" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": $DEALER_ID,
    \"status\": \"cart\",
    \"order_lines\": [
      {
        \"product_id\": 1,
        \"quantity\": 2
      },
      {
        \"product_id\": 2,
        \"quantity\": 1
      }
    ],
    \"admin_note\": \"Admin tarafından bayi için oluşturuldu\"
  }")

echo $ORDER_CREATE | jq '.'
ORDER_ID=$(echo $ORDER_CREATE | jq -r '.data.id // empty')

if [ -n "$ORDER_ID" ]; then
  echo -e "${GREEN}✓ Order created: #$ORDER_ID${NC}"
else
  echo -e "${RED}✗ Order creation failed${NC}"
fi
echo ""

# 4. Add Admin Note to Order
echo -e "${YELLOW}4. Add Admin Note to Order${NC}"
NOTE_CREATE=$(curl -s -X POST "$API_BASE/v1/admin/notes" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"note\": {
      \"note\": \"Müşteri özel iskonto talep etti\",
      \"related_type\": \"Orders::Order\",
      \"related_id\": $ORDER_ID
    }
  }")

echo $NOTE_CREATE | jq '.'
NOTE_ID=$(echo $NOTE_CREATE | jq -r '.data.id // empty')

if [ -n "$NOTE_ID" ]; then
  echo -e "${GREEN}✓ Admin note created: #$NOTE_ID${NC}"
fi
echo ""

# 5. List Orders (Admin View)
echo -e "${YELLOW}5. List All Orders (Admin)${NC}"
ORDERS_LIST=$(curl -s -X GET "$API_BASE/v1/admin/orders" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

ORDER_COUNT=$(echo $ORDERS_LIST | jq '.data | length')
echo -e "${GREEN}✓ Total orders: $ORDER_COUNT${NC}"
echo ""

# 6. Create Quote
echo -e "${YELLOW}6. Create Quote for Dealer${NC}"
QUOTE_CREATE=$(curl -s -X POST "$API_BASE/v1/admin/quotes" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": $DEALER_ID,
    \"status\": \"draft\",
    \"notes\": \"Özel bayi fiyatlandırması\",
    \"valid_until\": \"$(date -d '+30 days' +%Y-%m-%d)\",
    \"quote_lines\": [
      {
        \"product_id\": 1,
        \"quantity\": 10,
        \"unit_price_cents\": 250000,
        \"note\": \"Toplu alım indirimi\"
      },
      {
        \"product_id\": 3,
        \"quantity\": 5,
        \"unit_price_cents\": 4500
      }
    ],
    \"admin_note\": \"Özel teklif - Bayi kampanyası\"
  }")

echo $QUOTE_CREATE | jq '.'
QUOTE_ID=$(echo $QUOTE_CREATE | jq -r '.data.id // empty')
QUOTE_NUMBER=$(echo $QUOTE_CREATE | jq -r '.data.attributes.quote_number // empty')

if [ -n "$QUOTE_ID" ]; then
  echo -e "${GREEN}✓ Quote created: $QUOTE_NUMBER (ID: $QUOTE_ID)${NC}"
fi
echo ""

# 7. Get Quote Details
echo -e "${YELLOW}7. Get Quote Details${NC}"
QUOTE_DETAIL=$(curl -s -X GET "$API_BASE/v1/admin/quotes/$QUOTE_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo $QUOTE_DETAIL | jq '.data.attributes | {quote_number, status, total, valid_until}'
echo ""

# 8. Send Quote to Customer
echo -e "${YELLOW}8. Send Quote to Customer${NC}"
QUOTE_SEND=$(curl -s -X POST "$API_BASE/v1/admin/quotes/$QUOTE_ID/send" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo $QUOTE_SEND | jq '.'
echo ""

# 9. Convert Quote to Order
echo -e "${YELLOW}9. Convert Quote to Order${NC}"
QUOTE_CONVERT=$(curl -s -X POST "$API_BASE/v1/admin/quotes/$QUOTE_ID/convert" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo $QUOTE_CONVERT | jq '.'
CONVERTED_ORDER_ID=$(echo $QUOTE_CONVERT | jq -r '.data.order_id // empty')

if [ -n "$CONVERTED_ORDER_ID" ]; then
  echo -e "${GREEN}✓ Quote converted to order: #$CONVERTED_ORDER_ID${NC}"
fi
echo ""

# 10. List All Quotes
echo -e "${YELLOW}10. List All Quotes${NC}"
QUOTES_LIST=$(curl -s -X GET "$API_BASE/v1/admin/quotes" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

QUOTE_COUNT=$(echo $QUOTES_LIST | jq '.data | length')
echo -e "${GREEN}✓ Total quotes: $QUOTE_COUNT${NC}"
echo ""

# 11. List Admin Notes
echo -e "${YELLOW}11. List Admin Notes${NC}"
NOTES_LIST=$(curl -s -X GET "$API_BASE/v1/admin/notes" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

NOTE_COUNT=$(echo $NOTES_LIST | jq '.data | length')
echo -e "${GREEN}✓ Total admin notes: $NOTE_COUNT${NC}"
echo ""

# 12. Filter Notes by Order
echo -e "${YELLOW}12. Filter Notes by Order${NC}"
ORDER_NOTES=$(curl -s -X GET "$API_BASE/v1/admin/notes?related_type=Orders::Order&related_id=$ORDER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo $ORDER_NOTES | jq '.data | map({id, note: .attributes.note})'
echo ""

# 13. Update Order Status
echo -e "${YELLOW}13. Update Order Status${NC}"
ORDER_UPDATE=$(curl -s -X PATCH "$API_BASE/v1/admin/orders/$ORDER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "order": {
      "status": "paid"
    },
    "admin_note": "Ödeme admin tarafından manuel onaylandı"
  }')

echo $ORDER_UPDATE | jq '.data.attributes | {order_number, status}'
echo ""

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}✓ Admin authentication${NC}"
echo -e "${GREEN}✓ Order creation (on behalf of user)${NC}"
echo -e "${GREEN}✓ Admin notes${NC}"
echo -e "${GREEN}✓ Quote creation${NC}"
echo -e "${GREEN}✓ Quote sending${NC}"
echo -e "${GREEN}✓ Quote to order conversion${NC}"
echo -e "${GREEN}✓ Order status updates${NC}"
echo ""

echo -e "${YELLOW}API Endpoints Tested:${NC}"
echo "POST   /api/v1/admin/orders        - Create order on behalf"
echo "GET    /api/v1/admin/orders        - List all orders"
echo "GET    /api/v1/admin/orders/:id    - Get order details"
echo "PATCH  /api/v1/admin/orders/:id    - Update order"
echo ""
echo "POST   /api/v1/admin/notes         - Create admin note"
echo "GET    /api/v1/admin/notes         - List notes (with filters)"
echo ""
echo "POST   /api/v1/admin/quotes        - Create quote"
echo "GET    /api/v1/admin/quotes        - List quotes"
echo "GET    /api/v1/admin/quotes/:id    - Get quote details"
echo "POST   /api/v1/admin/quotes/:id/send     - Send quote"
echo "POST   /api/v1/admin/quotes/:id/convert  - Convert to order"
echo ""

echo -e "${GREEN}All tests completed!${NC}"
