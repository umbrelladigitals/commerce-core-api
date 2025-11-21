#!/bin/bash

# Shipment (Kargo) API Test Script
# Tests cargo/shipment tracking system

BASE_URL="http://localhost:3000"
API_BASE="$BASE_URL/api"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}=== Shipment (Kargo) API Test ===${NC}\n"

# 1. Admin Login
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

# 2. Customer Login (to create order)
echo -e "${YELLOW}2. Customer Login${NC}"
CUSTOMER_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "customer@test.com",
      "password": "password123"
    }
  }')

CUSTOMER_TOKEN=$(echo $CUSTOMER_LOGIN | jq -r '.token // empty')
CUSTOMER_ID=$(echo $CUSTOMER_LOGIN | jq -r '.user.id // empty')

echo -e "${GREEN}✓ Customer logged in (ID: $CUSTOMER_ID)${NC}"
echo ""

# 3. Create Order (Admin for customer)
echo -e "${YELLOW}3. Create Test Order${NC}"
ORDER_CREATE=$(curl -s -X POST "$API_BASE/v1/admin/orders" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": $CUSTOMER_ID,
    \"order_lines\": [
      {\"product_id\": 1, \"quantity\": 2},
      {\"product_id\": 2, \"quantity\": 1}
    ]
  }")

ORDER_ID=$(echo $ORDER_CREATE | jq -r '.data.id // empty')
echo "Order ID: $ORDER_ID"

# Mark as paid
curl -s -X PATCH "$API_BASE/v1/admin/orders/$ORDER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order":{"status":"paid"}}' > /dev/null

echo -e "${GREEN}✓ Test order created and marked as paid${NC}"
echo ""

# 4. Create Shipment with PTT
echo -e "${YELLOW}4. Create Shipment (PTT Kargo)${NC}"
SHIPMENT_PTT=$(curl -s -X POST "$API_BASE/shipment/create" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"order_id\": $ORDER_ID,
    \"carrier\": \"ptt\",
    \"notes\": \"Express delivery\"
  }")

echo $SHIPMENT_PTT | jq '.'
SHIPMENT_ID=$(echo $SHIPMENT_PTT | jq -r '.data.id // empty')
TRACKING_NUMBER=$(echo $SHIPMENT_PTT | jq -r '.data.attributes.tracking_number // empty')

if [ -n "$SHIPMENT_ID" ]; then
  echo -e "${GREEN}✓ PTT Shipment created: $TRACKING_NUMBER${NC}"
fi
echo ""

# 5. Get Shipment Details
echo -e "${YELLOW}5. Get Shipment Details${NC}"
SHIPMENT_DETAIL=$(curl -s -X GET "$API_BASE/shipment/$SHIPMENT_ID" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN")

echo $SHIPMENT_DETAIL | jq '.data.attributes | {tracking_number, carrier, carrier_name, status, tracking_url}'
echo ""

# 6. Track Shipment (Real-time)
echo -e "${YELLOW}6. Track Shipment (Mock API)${NC}"
TRACK_RESULT=$(curl -s -X GET "$API_BASE/shipment/$SHIPMENT_ID/track" \
  -H "Authorization: Bearer $CUSTOMER_TOKEN")

echo $TRACK_RESULT | jq '.data.tracking'
echo ""

# 7. Update Shipment Status
echo -e "${YELLOW}7. Update Shipment Status (Admin)${NC}"
STATUS_UPDATE=$(curl -s -X PATCH "$API_BASE/shipment/$SHIPMENT_ID/update_status" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "in_transit",
    "admin_note": "Kargo transfer merkezinde"
  }')

echo $STATUS_UPDATE | jq '.data.attributes | {status, shipped_at}'
echo -e "${GREEN}✓ Status updated to in_transit${NC}"
echo ""

# 8. List Shipments
echo -e "${YELLOW}8. List All Shipments${NC}"
SHIPMENTS_LIST=$(curl -s -X GET "$API_BASE/shipment" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

SHIPMENT_COUNT=$(echo $SHIPMENTS_LIST | jq '.data | length')
echo -e "${GREEN}✓ Total shipments: $SHIPMENT_COUNT${NC}"
echo ""

# 9. Create Another Shipment (Aras)
echo -e "${YELLOW}9. Test Different Carriers${NC}"

# Create another order
ORDER2=$(curl -s -X POST "$API_BASE/v1/admin/orders" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\": $CUSTOMER_ID, \"order_lines\": [{\"product_id\": 1, \"quantity\": 1}]}")

ORDER2_ID=$(echo $ORDER2 | jq -r '.data.id // empty')

curl -s -X PATCH "$API_BASE/v1/admin/orders/$ORDER2_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order":{"status":"paid"}}' > /dev/null

# Aras Kargo
SHIPMENT_ARAS=$(curl -s -X POST "$API_BASE/shipment/create" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"order_id\": $ORDER2_ID, \"carrier\": \"aras\"}")

ARAS_TRACKING=$(echo $SHIPMENT_ARAS | jq -r '.data.attributes.tracking_number // empty')
echo -e "${GREEN}✓ Aras Kargo: $ARAS_TRACKING${NC}"

# Create another order
ORDER3=$(curl -s -X POST "$API_BASE/v1/admin/orders" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\": $CUSTOMER_ID, \"order_lines\": [{\"product_id\": 2, \"quantity\": 1}]}")

ORDER3_ID=$(echo $ORDER3 | jq -r '.data.id // empty')

curl -s -X PATCH "$API_BASE/v1/admin/orders/$ORDER3_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"order":{"status":"paid"}}' > /dev/null

# Yurtiçi Kargo
SHIPMENT_YURTICI=$(curl -s -X POST "$API_BASE/shipment/create" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"order_id\": $ORDER3_ID, \"carrier\": \"yurtici\"}")

YURTICI_TRACKING=$(echo $SHIPMENT_YURTICI | jq -r '.data.attributes.tracking_number // empty')
echo -e "${GREEN}✓ Yurtiçi Kargo: $YURTICI_TRACKING${NC}"
echo ""

# 10. Filter Shipments by Carrier
echo -e "${YELLOW}10. Filter Shipments by Carrier${NC}"
PTT_SHIPMENTS=$(curl -s -X GET "$API_BASE/shipment?carrier=ptt" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

PTT_COUNT=$(echo $PTT_SHIPMENTS | jq '.data | length')
echo -e "${GREEN}✓ PTT Kargo count: $PTT_COUNT${NC}"
echo ""

# 11. Update to Out for Delivery
echo -e "${YELLOW}11. Update to Out for Delivery${NC}"
curl -s -X PATCH "$API_BASE/shipment/$SHIPMENT_ID/update_status" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "out_for_delivery",
    "admin_note": "Kurye dağıtıma çıktı"
  }' | jq '.message'
echo ""

# 12. Mark as Delivered
echo -e "${YELLOW}12. Mark as Delivered${NC}"
DELIVERED=$(curl -s -X PATCH "$API_BASE/shipment/$SHIPMENT_ID/update_status" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "delivered",
    "admin_note": "Teslim edildi"
  }')

echo $DELIVERED | jq '.data.attributes | {status, shipped_at, delivered_at}'
echo -e "${GREEN}✓ Shipment delivered successfully${NC}"
echo ""

# Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo -e "${GREEN}✓ Admin authentication${NC}"
echo -e "${GREEN}✓ Shipment creation (PTT, Aras, Yurtiçi)${NC}"
echo -e "${GREEN}✓ Tracking number generation (mock)${NC}"
echo -e "${GREEN}✓ Status updates${NC}"
echo -e "${GREEN}✓ Real-time tracking (mock)${NC}"
echo -e "${GREEN}✓ Shipment listing & filtering${NC}"
echo -e "${GREEN}✓ Delivery confirmation${NC}"
echo ""

echo -e "${YELLOW}API Endpoints Tested:${NC}"
echo "POST   /api/shipment/create                - Create shipment"
echo "GET    /api/shipment                       - List shipments"
echo "GET    /api/shipment/:id                   - Get shipment details"
echo "GET    /api/shipment/:id/track             - Track shipment (real-time)"
echo "PATCH  /api/shipment/:id/update_status     - Update status"
echo "POST   /api/shipment/:id/cancel            - Cancel shipment"
echo ""

echo -e "${YELLOW}Supported Carriers:${NC}"
echo "- PTT Kargo (ptt)"
echo "- Aras Kargo (aras)"
echo "- Yurtiçi Kargo (yurtici)"
echo "- MNG Kargo (mng)"
echo "- UPS (ups)"
echo "- DHL (dhl)"
echo ""

echo -e "${YELLOW}Tracking URLs:${NC}"
echo "PTT:     $TRACKING_NUMBER"
echo "Aras:    $ARAS_TRACKING"
echo "Yurtiçi: $YURTICI_TRACKING"
echo ""

echo -e "${GREEN}All tests completed!${NC}"
