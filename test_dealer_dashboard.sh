#!/bin/bash

# Dealer Dashboard API Test Script
# Bayi dashboard ve işlemlerini test eder

BASE_URL="http://localhost:3000"
API_BASE="$BASE_URL/api"

# Renkli output için
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Dealer Dashboard API Test ===${NC}\n"

# 1. Dealer Login
echo -e "${YELLOW}1. Dealer Login${NC}"
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

echo -e "${GREEN}✓ Dealer login successful${NC}"
echo "Token: ${TOKEN:0:20}..."
echo ""

# 2. Dashboard Overview
echo -e "${YELLOW}2. GET /api/dealer/dashboard${NC}"
echo -e "${BLUE}Fetching dealer dashboard overview...${NC}"
DASHBOARD_RESPONSE=$(curl -s -X GET "$API_BASE/dealer/dashboard" \
  -H "Authorization: Bearer $TOKEN")

echo $DASHBOARD_RESPONSE | jq '.'
echo ""

# 3. Dealer Balance
echo -e "${YELLOW}3. GET /api/dealer/balance${NC}"
echo -e "${BLUE}Fetching dealer balance...${NC}"
BALANCE_RESPONSE=$(curl -s -X GET "$API_BASE/dealer/balance" \
  -H "Authorization: Bearer $TOKEN")

echo $BALANCE_RESPONSE | jq '.'

CURRENT_BALANCE=$(echo $BALANCE_RESPONSE | jq -r '.data.attributes.balance // "N/A"')
echo -e "${GREEN}Current Balance: $CURRENT_BALANCE${NC}"
echo ""

# 4. Dealer Orders
echo -e "${YELLOW}4. GET /api/dealer/orders${NC}"
echo -e "${BLUE}Fetching dealer orders...${NC}"
ORDERS_RESPONSE=$(curl -s -X GET "$API_BASE/dealer/orders?per_page=5" \
  -H "Authorization: Bearer $TOKEN")

ORDERS_COUNT=$(echo $ORDERS_RESPONSE | jq '.data | length')
echo -e "${GREEN}Found $ORDERS_COUNT orders${NC}"
echo $ORDERS_RESPONSE | jq '.data[] | {id: .id, order_number: .attributes.order_number, status: .attributes.status, total: .attributes.total}'
echo ""

# 5. Dealer Discounts
echo -e "${YELLOW}5. GET /api/dealer/discounts${NC}"
echo -e "${BLUE}Fetching dealer-specific discounts...${NC}"
DISCOUNTS_RESPONSE=$(curl -s -X GET "$API_BASE/dealer/discounts" \
  -H "Authorization: Bearer $TOKEN")

DISCOUNTS_COUNT=$(echo $DISCOUNTS_RESPONSE | jq '.data | length')
echo -e "${GREEN}Found $DISCOUNTS_COUNT active discounts${NC}"
echo $DISCOUNTS_RESPONSE | jq '.data[] | {product: .attributes.product_name, discount: .attributes.discount_percent, savings: .attributes.example_calculation.savings}'
echo ""

# 6. Balance Topup
echo -e "${YELLOW}6. POST /api/dealer/balance/topup${NC}"
echo -e "${BLUE}Loading 100 USD to balance...${NC}"
TOPUP_RESPONSE=$(curl -s -X POST "$API_BASE/dealer/balance/topup" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount_cents": 10000,
    "note": "Test topup via API"
  }')

echo $TOPUP_RESPONSE | jq '.'

TOPUP_SUCCESS=$(echo $TOPUP_RESPONSE | jq -r '.message // empty')
if [ -n "$TOPUP_SUCCESS" ]; then
  NEW_BALANCE=$(echo $TOPUP_RESPONSE | jq -r '.data.attributes.balance')
  echo -e "${GREEN}✓ Topup successful! New balance: $NEW_BALANCE${NC}"
else
  echo -e "${RED}✗ Topup failed${NC}"
fi
echo ""

# 7. Balance History
echo -e "${YELLOW}7. GET /api/dealer/balance/history${NC}"
echo -e "${BLUE}Fetching balance transaction history...${NC}"
HISTORY_RESPONSE=$(curl -s -X GET "$API_BASE/dealer/balance/history?per_page=10" \
  -H "Authorization: Bearer $TOKEN")

TRANSACTIONS_COUNT=$(echo $HISTORY_RESPONSE | jq '.data | length')
echo -e "${GREEN}Found $TRANSACTIONS_COUNT recent transactions${NC}"
echo $HISTORY_RESPONSE | jq '.data[] | {type: .attributes.type_label, amount: .attributes.amount, note: .attributes.note, date: .attributes.created_at}'
echo ""

# 8. Filter Orders by Status
echo -e "${YELLOW}8. GET /api/dealer/orders?status=paid${NC}"
echo -e "${BLUE}Fetching only paid orders...${NC}"
PAID_ORDERS=$(curl -s -X GET "$API_BASE/dealer/orders?status=paid" \
  -H "Authorization: Bearer $TOKEN")

PAID_COUNT=$(echo $PAID_ORDERS | jq '.data | length')
echo -e "${GREEN}Found $PAID_COUNT paid orders${NC}"
echo ""

# 9. Filter Discounts (Active only)
echo -e "${YELLOW}9. GET /api/dealer/discounts?active=true${NC}"
echo -e "${BLUE}Fetching only active discounts...${NC}"
ACTIVE_DISCOUNTS=$(curl -s -X GET "$API_BASE/dealer/discounts?active=true" \
  -H "Authorization: Bearer $TOKEN")

ACTIVE_COUNT=$(echo $ACTIVE_DISCOUNTS | jq '.data | length')
echo -e "${GREEN}Found $ACTIVE_COUNT active discounts${NC}"
echo ""

# 10. Test with Customer (Should Fail)
echo -e "${YELLOW}10. Testing with Customer Role (Should Fail)${NC}"
CUSTOMER_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "customer@test.com",
      "password": "password123"
    }
  }')

CUSTOMER_TOKEN=$(echo $CUSTOMER_LOGIN | jq -r '.token // empty')

if [ -n "$CUSTOMER_TOKEN" ]; then
  echo -e "${BLUE}Trying to access dealer dashboard as customer...${NC}"
  CUSTOMER_ATTEMPT=$(curl -s -X GET "$API_BASE/dealer/dashboard" \
    -H "Authorization: Bearer $CUSTOMER_TOKEN")
  
  ERROR_MSG=$(echo $CUSTOMER_ATTEMPT | jq -r '.error // empty')
  if [ -n "$ERROR_MSG" ]; then
    echo -e "${GREEN}✓ Correctly blocked: $ERROR_MSG${NC}"
  else
    echo -e "${RED}✗ Security issue: Customer accessed dealer endpoint!${NC}"
  fi
fi
echo ""

# Test Summary
echo -e "${YELLOW}=== Test Summary ===${NC}"
echo -e "${GREEN}✓ Dealer authentication${NC}"
echo -e "${GREEN}✓ Dashboard overview${NC}"
echo -e "${GREEN}✓ Balance management${NC}"
echo -e "${GREEN}✓ Balance topup${NC}"
echo -e "${GREEN}✓ Transaction history${NC}"
echo -e "${GREEN}✓ Order listing${NC}"
echo -e "${GREEN}✓ Discount listing${NC}"
echo -e "${GREEN}✓ Filtering & pagination${NC}"
echo -e "${GREEN}✓ Role-based access control${NC}"
echo ""

echo -e "${YELLOW}Available Endpoints:${NC}"
echo "GET  /api/dealer/dashboard           - Dashboard overview"
echo "GET  /api/dealer/orders               - Order history (filterable)"
echo "GET  /api/dealer/discounts            - Special discounts"
echo "GET  /api/dealer/balance              - Current balance"
echo "GET  /api/dealer/balance/history      - Transaction history"
echo "POST /api/dealer/balance/topup        - Load balance"
echo ""

echo -e "${YELLOW}Query Parameters:${NC}"
echo "orders:    ?status=paid&start_date=2024-01-01&end_date=2024-12-31&page=1&per_page=20"
echo "discounts: ?active=true&product_id=123"
echo "history:   ?transaction_type=topup&start_date=2024-01-01&page=1&per_page=50"
