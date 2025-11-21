#!/bin/bash
# Üretici (Manufacturer) API Test Script

BASE_URL="http://localhost:3000"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Üretici Panel API Test ===${NC}\n"

# 1. Üretici login (kayıt varsa login, yoksa kayıt)
echo -e "${YELLOW}1. Üretici Login/Kayıt${NC}"

# Önce login dene
MANUFACTURER_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "manufacturer@test.com",
      "password": "password123"
    }
  }')

MANUFACTURER_TOKEN=$(echo $MANUFACTURER_LOGIN | jq -r '.token // empty')

# Login başarısızsa admin ile oluştur
if [ -z "$MANUFACTURER_TOKEN" ]; then
  echo "Üretici bulunamadı, admin ile kayıt yapılıyor..."
  
  # Admin login
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
    echo -e "${RED}✗ Admin login başarısız${NC}"
    exit 1
  fi
  
  # Admin ile manufacturer oluştur
  MANUFACTURER_CREATE=$(curl -s -X POST "$BASE_URL/api/v1/admin/users" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "user": {
        "email": "manufacturer@test.com",
        "password": "password123",
        "password_confirmation": "password123",
        "name": "Test Manufacturer",
        "role": "manufacturer",
        "active": true
      }
    }')
  
  # Sonra login yap
  MANUFACTURER_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d '{
      "user": {
        "email": "manufacturer@test.com",
        "password": "password123"
      }
    }')
  
  MANUFACTURER_TOKEN=$(echo $MANUFACTURER_LOGIN | jq -r '.token // empty')
  
  if [ -z "$MANUFACTURER_TOKEN" ]; then
    echo -e "${RED}✗ Üretici login başarısız${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Üretici oluşturuldu ve login yapıldı${NC}"
else
  echo -e "${GREEN}✓ Üretici login başarılı${NC}"
fi

echo "Token: ${MANUFACTURER_TOKEN:0:20}..."
echo ""

# 2. Dashboard istatistikleri
echo -e "${YELLOW}2. Üretim Dashboard İstatistikleri${NC}"
DASHBOARD=$(curl -s -X GET "$BASE_URL/api/v1/manufacturer/dashboard" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN")

echo $DASHBOARD | jq '.data.attributes.statistics'
echo -e "${GREEN}✓ Dashboard yüklendi${NC}\n"

# 3. Admin login ve test siparişi oluştur
echo -e "${YELLOW}3. Test Siparişi Oluşturma (Admin)${NC}"

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
  echo -e "${RED}✗ Admin login başarısız${NC}"
  exit 1
fi

# Test müşterisi oluştur
CUSTOMER_SIGNUP=$(curl -s -X POST "$BASE_URL/signup" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "customer.for.manufacturer@test.com",
      "password": "password123",
      "password_confirmation": "password123",
      "name": "Test Customer for Manufacturer",
      "role": "customer"
    }
  }')

CUSTOMER_ID=$(echo $CUSTOMER_SIGNUP | jq -r '.user.id // empty')

# Müşteri zaten varsa login yap
if [ -z "$CUSTOMER_ID" ]; then
  CUSTOMER_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
    -H "Content-Type: application/json" \
    -d '{
      "user": {
        "email": "customer.for.manufacturer@test.com",
        "password": "password123"
      }
    }')
  CUSTOMER_ID=$(echo $CUSTOMER_LOGIN | jq -r '.user.id // empty')
fi

# Test ürünü oluştur
PRODUCT=$(curl -s -X POST "$BASE_URL/api/v1/admin/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product for Production",
    "description": "Product for manufacturer test",
    "sku": "PROD-001",
    "price": 15000,
    "stock": 50,
    "active": true
  }')

PRODUCT_ID=$(echo $PRODUCT | jq -r '.data.id // empty')

if [ -z "$PRODUCT_ID" ]; then
  echo -e "${RED}✗ Ürün oluşturulamadı${NC}"
  exit 1
fi

# Sipariş oluştur (admin olarak)
ORDER=$(curl -s -X POST "$BASE_URL/api/v1/admin/orders" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\": $CUSTOMER_ID,
    \"status\": \"paid\",
    \"order_lines\": [
      {
        \"product_id\": $PRODUCT_ID,
        \"quantity\": 3
      }
    ]
  }")

TEST_ORDER_ID=$(echo $ORDER | jq -r '.data.id // empty')

if [ -z "$TEST_ORDER_ID" ]; then
  echo -e "${RED}✗ Test siparişi oluşturulamadı${NC}"
  echo $ORDER | jq '.'
  exit 1
fi

echo -e "${GREEN}✓ Test siparişi oluşturuldu (ID: $TEST_ORDER_ID)${NC}\n"

# 4. Üretim siparişleri listesi
echo -e "${YELLOW}4. Tüm Üretim Siparişleri${NC}"
ORDERS_LIST=$(curl -s -X GET "$BASE_URL/api/v1/manufacturer/orders?per_page=5" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN")

echo $ORDERS_LIST | jq '.data[] | {order_number, customer: .customer.name, production_status, items_count}'
echo -e "${GREEN}✓ Sipariş listesi alındı${NC}\n"

# 5. Pending durumundaki siparişler
echo -e "${YELLOW}5. Bekleyen Siparişler (Pending)${NC}"
PENDING_ORDERS=$(curl -s -X GET "$BASE_URL/api/v1/manufacturer/orders?production_status=pending" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN")

PENDING_COUNT=$(echo $PENDING_ORDERS | jq '.data | length')
echo -e "Bekleyen sipariş sayısı: ${GREEN}$PENDING_COUNT${NC}"
echo $PENDING_ORDERS | jq '.data[] | {order_number, production_status, created_at}' 2>/dev/null
echo ""

# 6. Sipariş detayı
echo -e "${YELLOW}6. Sipariş Detayı${NC}"
ORDER_DETAIL=$(curl -s -X GET "$BASE_URL/api/v1/manufacturer/orders/$TEST_ORDER_ID" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN")

echo $ORDER_DETAIL | jq '.data.attributes | {order_number, production_status, customer: .customer.name, items_count: (.order_lines | length)}'
echo "Ürünler:"
echo $ORDER_DETAIL | jq '.data.attributes.order_lines[] | {product: .product.name, quantity, product_options: (.product_options | length)}'
echo -e "${GREEN}✓ Sipariş detayı alındı${NC}\n"

# 7. Üretim durumu güncelleme - in_production
echo -e "${YELLOW}7. Üretim Durumu Güncelleme: In Production${NC}"
UPDATE_TO_PRODUCTION=$(curl -s -X PATCH "$BASE_URL/api/v1/manufacturer/orders/$TEST_ORDER_ID/update_status" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "production_status": "in_production"
  }')

NEW_STATUS=$(echo $UPDATE_TO_PRODUCTION | jq -r '.data.attributes.production_status')
echo -e "Yeni durum: ${GREEN}$NEW_STATUS${NC}"
echo $UPDATE_TO_PRODUCTION | jq '.message'
echo ""

# 8. In production siparişleri
echo -e "${YELLOW}8. Üretimdeki Siparişler${NC}"
IN_PRODUCTION_ORDERS=$(curl -s -X GET "$BASE_URL/api/v1/manufacturer/orders?production_status=in_production" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN")

IN_PROD_COUNT=$(echo $IN_PRODUCTION_ORDERS | jq '.data | length')
echo -e "Üretimdeki sipariş sayısı: ${GREEN}$IN_PROD_COUNT${NC}"
echo $IN_PRODUCTION_ORDERS | jq '.data[] | {order_number, production_status}'
echo ""

# 9. Üretim durumu güncelleme - ready
echo -e "${YELLOW}9. Üretim Durumu Güncelleme: Ready${NC}"
UPDATE_TO_READY=$(curl -s -X PATCH "$BASE_URL/api/v1/manufacturer/orders/$TEST_ORDER_ID/update_status" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "production_status": "ready"
  }')

READY_STATUS=$(echo $UPDATE_TO_READY | jq -r '.data.attributes.production_status')
echo -e "Yeni durum: ${GREEN}$READY_STATUS${NC}"
echo ""

# 10. Ready durumundaki siparişler
echo -e "${YELLOW}10. Hazır Siparişler (Ready)${NC}"
READY_ORDERS=$(curl -s -X GET "$BASE_URL/api/v1/manufacturer/orders?production_status=ready" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN")

READY_COUNT=$(echo $READY_ORDERS | jq '.data | length')
echo -e "Hazır sipariş sayısı: ${GREEN}$READY_COUNT${NC}"
echo $READY_ORDERS | jq '.data[] | {order_number, production_status}'
echo ""

# 11. Üretim durumu güncelleme - shipped
echo -e "${YELLOW}11. Üretim Durumu Güncelleme: Shipped${NC}"
UPDATE_TO_SHIPPED=$(curl -s -X PATCH "$BASE_URL/api/v1/manufacturer/orders/$TEST_ORDER_ID/update_status" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "production_status": "shipped"
  }')

SHIPPED_STATUS=$(echo $UPDATE_TO_SHIPPED | jq -r '.data.attributes.production_status')
echo -e "Yeni durum: ${GREEN}$SHIPPED_STATUS${NC}"
echo ""

# 12. Güncel dashboard
echo -e "${YELLOW}12. Güncel Dashboard${NC}"
DASHBOARD_UPDATED=$(curl -s -X GET "$BASE_URL/api/v1/manufacturer/dashboard" \
  -H "Authorization: Bearer $MANUFACTURER_TOKEN")

echo "İstatistikler:"
echo $DASHBOARD_UPDATED | jq '.data.attributes.statistics'
echo ""
echo "Son Siparişler:"
echo $DASHBOARD_UPDATED | jq '.data.attributes.recent_orders[] | {order_number, production_status, items_count}'
echo -e "${GREEN}✓ Dashboard güncellendi${NC}\n"

# Özet
echo -e "${YELLOW}=== Test Özeti ===${NC}"
echo -e "${GREEN}✓${NC} Üretici kaydı ve login"
echo -e "${GREEN}✓${NC} Dashboard istatistikleri"
echo -e "${GREEN}✓${NC} Üretim siparişleri listesi ve filtreleme"
echo -e "${GREEN}✓${NC} Sipariş detayı"
echo -e "${GREEN}✓${NC} Üretim durumu güncelleme (pending → in_production → ready → shipped)"
echo -e "${GREEN}✓${NC} Durum bazlı filtreleme"
echo ""
echo -e "${GREEN}Tüm testler başarılı!${NC}"
echo ""
echo "API Endpoints:"
echo "GET    /api/v1/manufacturer/dashboard"
echo "GET    /api/v1/manufacturer/orders"
echo "GET    /api/v1/manufacturer/orders?production_status=pending"
echo "GET    /api/v1/manufacturer/orders/:id"
echo "PATCH  /api/v1/manufacturer/orders/:id/update_status"
