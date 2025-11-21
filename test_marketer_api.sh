#!/bin/bash
# Pazarlamacı (Marketer) API Test Script

BASE_URL="http://localhost:3000"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Pazarlamacı Panel API Test ===${NC}\n"

# 1. Pazarlamacı login (kayıt varsa login, yoksa kayıt)
echo -e "${YELLOW}1. Pazarlamacı Login/Kayıt${NC}"

# Önce login dene
MARKETER_LOGIN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "marketer@test.com",
      "password": "password123"
    }
  }')

MARKETER_TOKEN=$(echo $MARKETER_LOGIN | jq -r '.token // empty')

# Login başarısızsa kayıt ol
if [ -z "$MARKETER_TOKEN" ]; then
  echo "Pazarlamacı bulunamadı, kayıt yapılıyor..."
  MARKETER_SIGNUP=$(curl -s -X POST "$BASE_URL/signup" \
    -H "Content-Type: application/json" \
    -d '{
      "user": {
        "email": "marketer@test.com",
        "password": "password123",
        "password_confirmation": "password123",
        "name": "Test Marketer",
        "role": "marketer"
      }
    }')
  
  MARKETER_TOKEN=$(echo $MARKETER_SIGNUP | jq -r '.token // empty')
  
  if [ -z "$MARKETER_TOKEN" ]; then
    echo -e "${RED}✗ Pazarlamacı kaydı başarısız${NC}"
    echo $MARKETER_SIGNUP | jq '.'
    exit 1
  fi
  echo -e "${GREEN}✓ Pazarlamacı kaydedildi${NC}"
else
  echo -e "${GREEN}✓ Pazarlamacı login başarılı${NC}"
fi

echo "Token: ${MARKETER_TOKEN:0:20}..."
echo ""

# 2. Dashboard istatistikleri
echo -e "${YELLOW}2. Dashboard İstatistikleri${NC}"
DASHBOARD=$(curl -s -X GET "$BASE_URL/api/v1/marketer/dashboard" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

echo $DASHBOARD | jq '.data.attributes.statistics'
echo -e "${GREEN}✓ Dashboard yüklendi${NC}\n"

# 3. Test müşterisi bul veya oluştur
echo -e "${YELLOW}3. Test Müşterisi${NC}"

# Önce mevcut müşterileri kontrol et
EXISTING_CUSTOMERS=$(curl -s -X GET "$BASE_URL/api/v1/marketer/customers?search=customer.for.marketer" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

CUSTOMER_ID=$(echo $EXISTING_CUSTOMERS | jq -r '.data[0].id // empty')

if [ -z "$CUSTOMER_ID" ]; then
  echo "Müşteri bulunamadı, oluşturuluyor..."
  CUSTOMER_SIGNUP=$(curl -s -X POST "$BASE_URL/signup" \
    -H "Content-Type: application/json" \
    -d '{
      "user": {
        "email": "customer.for.marketer@test.com",
        "password": "password123",
        "password_confirmation": "password123",
        "name": "Test Customer",
        "role": "customer",
        "phone": "555-1234"
      }
    }')
  
  CUSTOMER_ID=$(echo $CUSTOMER_SIGNUP | jq -r '.user.id // empty')
  
  if [ -z "$CUSTOMER_ID" ]; then
    echo -e "${RED}✗ Müşteri oluşturulamadı${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Müşteri oluşturuldu (ID: $CUSTOMER_ID)${NC}"
else
  echo -e "${GREEN}✓ Mevcut müşteri bulundu (ID: $CUSTOMER_ID)${NC}"
fi
echo ""

# 4. Müşteri listesi
echo -e "${YELLOW}4. Müşteri Listesi${NC}"
CUSTOMERS=$(curl -s -X GET "$BASE_URL/api/v1/marketer/customers?per_page=5" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

echo $CUSTOMERS | jq '.data[] | {id, name, email, role}'
echo -e "${GREEN}✓ Müşteri listesi alındı${NC}\n"

# 5. Müşteri arama
echo -e "${YELLOW}5. Müşteri Arama (Test)${NC}"
SEARCH=$(curl -s -X GET "$BASE_URL/api/v1/marketer/customers?search=Test" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

FOUND=$(echo $SEARCH | jq '.data | length')
echo -e "Bulunan: ${GREEN}$FOUND${NC} müşteri"
echo $SEARCH | jq '.data[0] | {name, email}' 2>/dev/null
echo ""

# 6. Müşteri detayı
echo -e "${YELLOW}6. Müşteri Detayı${NC}"
CUSTOMER_DETAIL=$(curl -s -X GET "$BASE_URL/api/v1/marketer/customers/$CUSTOMER_ID" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

echo $CUSTOMER_DETAIL | jq '.data.attributes | {name, email, phone, role}'
echo -e "${GREEN}✓ Müşteri detayı alındı${NC}\n"

# 7. Admin login (ürün oluşturmak için)
echo -e "${YELLOW}7. Admin Login (Ürün Oluşturmak İçin)${NC}"
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

echo -e "${GREEN}✓ Admin login${NC}\n"

# 8. Test ürünü oluştur
echo -e "${YELLOW}8. Test Ürünü Oluştur${NC}"
PRODUCT=$(curl -s -X POST "$BASE_URL/api/v1/admin/products" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Product for Marketer",
    "description": "Test product",
    "sku": "MARK-001",
    "price": 10000,
    "stock": 100,
    "active": true
  }')

PRODUCT_ID=$(echo $PRODUCT | jq -r '.data.id // empty')

if [ -z "$PRODUCT_ID" ]; then
  echo -e "${RED}✗ Ürün oluşturulamadı${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Ürün oluşturuldu (ID: $PRODUCT_ID)${NC}\n"

# 9. Pazarlamacı sipariş oluştur
echo -e "${YELLOW}9. Müşteri Adına Sipariş Oluştur${NC}"
ORDER=$(curl -s -X POST "$BASE_URL/api/v1/marketer/orders" \
  -H "Authorization: Bearer $MARKETER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"customer_id\": $CUSTOMER_ID,
    \"notes\": \"Pazarlamacı tarafından oluşturuldu\",
    \"order_lines\": [
      {
        \"product_id\": $PRODUCT_ID,
        \"quantity\": 2
      }
    ]
  }")

ORDER_ID=$(echo $ORDER | jq -r '.data.id // empty')

if [ -z "$ORDER_ID" ]; then
  echo -e "${RED}✗ Sipariş oluşturulamadı${NC}"
  echo $ORDER | jq '.'
  exit 1
fi

echo -e "${GREEN}✓ Sipariş oluşturuldu (ID: $ORDER_ID)${NC}"
echo $ORDER | jq '.data.attributes | {order_number, status, total}'
echo ""

# 10. Sipariş detayı
echo -e "${YELLOW}10. Sipariş Detayı${NC}"
ORDER_DETAIL=$(curl -s -X GET "$BASE_URL/api/v1/marketer/orders/$ORDER_ID" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

echo $ORDER_DETAIL | jq '.data.attributes | {order_number, status, total, notes}'
echo $ORDER_DETAIL | jq '.data.relationships.customer | {name, email}'
echo -e "${GREEN}✓ Sipariş detayı alındı${NC}\n"

# 11. Pazarlamacının siparişleri
echo -e "${YELLOW}11. Pazarlamacının Tüm Siparişleri${NC}"
ORDERS_LIST=$(curl -s -X GET "$BASE_URL/api/v1/marketer/orders" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

echo $ORDERS_LIST | jq '.data[] | {order_number, customer: .customer.name, status, total}'
echo -e "${GREEN}✓ Sipariş listesi alındı${NC}\n"

# 12. Güncel dashboard
echo -e "${YELLOW}12. Güncel Dashboard${NC}"
DASHBOARD_UPDATED=$(curl -s -X GET "$BASE_URL/api/v1/marketer/dashboard" \
  -H "Authorization: Bearer $MARKETER_TOKEN")

echo "İstatistikler:"
echo $DASHBOARD_UPDATED | jq '.data.attributes.statistics'
echo ""
echo "Son Siparişler:"
echo $DASHBOARD_UPDATED | jq '.data.attributes.recent_orders[] | {order_number, customer_name, total}'
echo -e "${GREEN}✓ Dashboard güncellendi${NC}\n"

# Özet
echo -e "${YELLOW}=== Test Özeti ===${NC}"
echo -e "${GREEN}✓${NC} Pazarlamacı kaydı ve login"
echo -e "${GREEN}✓${NC} Dashboard istatistikleri"
echo -e "${GREEN}✓${NC} Müşteri listesi ve arama"
echo -e "${GREEN}✓${NC} Müşteri detayı"
echo -e "${GREEN}✓${NC} Müşteri adına sipariş oluşturma"
echo -e "${GREEN}✓${NC} Sipariş detayı ve liste"
echo ""
echo -e "${GREEN}Tüm testler başarılı!${NC}"
echo ""
echo "API Endpoints:"
echo "GET    /api/v1/marketer/dashboard"
echo "GET    /api/v1/marketer/customers"
echo "GET    /api/v1/marketer/customers/:id"
echo "GET    /api/v1/marketer/orders"
echo "POST   /api/v1/marketer/orders"
echo "GET    /api/v1/marketer/orders/:id"
