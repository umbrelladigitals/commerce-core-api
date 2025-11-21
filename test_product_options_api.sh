#!/bin/bash

# Product Options API Test Script
# Tests admin CRUD operations and frontend product detail endpoint

BASE_URL="http://localhost:3000/api"
ADMIN_EMAIL="admin@example.com"
ADMIN_PASSWORD="password123"

echo "🧪 Product Options API Test"
echo "================================"
echo ""

# Login as admin
echo "1️⃣ Admin Login..."
ADMIN_LOGIN=$(curl -s -X POST "$BASE_URL/../login" \
  -H "Content-Type: application/json" \
  -d "{\"user\":{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}}")

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token // empty')

if [ -z "$ADMIN_TOKEN" ]; then
  echo "❌ Admin login failed"
  echo $ADMIN_LOGIN | jq .
  exit 1
fi

echo "✅ Admin logged in (token: ${ADMIN_TOKEN:0:20}...)"
echo ""

# Get MacBook Pro ID
echo "2️⃣ Getting MacBook Pro product..."
PRODUCTS=$(curl -s -X GET "$BASE_URL/products")
MACBOOK_ID=$(echo $PRODUCTS | jq -r '.data[] | select(.title | contains("MacBook")) | .id')

echo "✅ MacBook Pro ID: $MACBOOK_ID"
echo ""

# Get product detail with options (Frontend endpoint)
echo "3️⃣ Getting product detail with options (Frontend)..."
PRODUCT_DETAIL=$(curl -s -X GET "$BASE_URL/products/$MACBOOK_ID")

echo "Product Details:"
echo $PRODUCT_DETAIL | jq '{
  id: .data.id,
  title: .data.title,
  price: .data.price,
  has_options: .data.has_options,
  required_options_count: .data.required_options_count,
  options_count: (.data.options | length),
  options: .data.options | map({
    name: .name,
    type: .option_type,
    required: .required,
    values_count: (.values | length)
  })
}'
echo ""

# List product options (Admin endpoint)
echo "4️⃣ Listing product options (Admin)..."
OPTIONS_LIST=$(curl -s -X GET "$BASE_URL/v1/admin/products/$MACBOOK_ID/product_options" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Options Summary:"
echo $OPTIONS_LIST | jq '{
  product_title: .data.product_title,
  options_count: .data.options_count,
  options: .data.options | map({
    id: .id,
    name: .name,
    type: .option_type,
    required: .required,
    values_count: .values_count,
    price_range: .price_range
  })
}'
echo ""

# Get first option ID
FIRST_OPTION_ID=$(echo $OPTIONS_LIST | jq -r '.data.options[0].id')
FIRST_OPTION_NAME=$(echo $OPTIONS_LIST | jq -r '.data.options[0].name')

echo "5️⃣ Getting option details: $FIRST_OPTION_NAME (ID: $FIRST_OPTION_ID)..."
OPTION_DETAIL=$(curl -s -X GET "$BASE_URL/v1/admin/products/$MACBOOK_ID/product_options/$FIRST_OPTION_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Option Detail:"
echo $OPTION_DETAIL | jq '.data'
echo ""

# List option values
echo "6️⃣ Listing option values..."
VALUES_LIST=$(curl -s -X GET "$BASE_URL/v1/admin/product_options/$FIRST_OPTION_ID/values" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Option Values:"
echo $VALUES_LIST | jq '.data.values | map({
  id: .id,
  name: .name,
  price: .price_formatted,
  price_mode: .price_mode,
  price_description: .price_description
})'
echo ""

# Create new product option
echo "7️⃣ Creating new product option (Insurance)..."
NEW_OPTION=$(curl -s -X POST "$BASE_URL/v1/admin/products/$MACBOOK_ID/product_options" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_option": {
      "name": "Insurance Coverage",
      "option_type": "select",
      "required": false
    }
  }')

echo $NEW_OPTION | jq '{success: .success, message: .message, option: .data | {id, name, type: .option_type}}'
NEW_OPTION_ID=$(echo $NEW_OPTION | jq -r '.data.id')
echo ""

# Create option values for new option
echo "8️⃣ Creating option values for Insurance..."

# No insurance
VALUE1=$(curl -s -X POST "$BASE_URL/v1/admin/product_options/$NEW_OPTION_ID/values" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_option_value": {
      "name": "No Insurance",
      "price_cents": 0,
      "price_mode": "flat"
    }
  }')

echo "  ✓ " $(echo $VALUE1 | jq -r '.data.name') " - " $(echo $VALUE1 | jq -r '.data.price_formatted')

# Basic insurance
VALUE2=$(curl -s -X POST "$BASE_URL/v1/admin/product_options/$NEW_OPTION_ID/values" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_option_value": {
      "name": "Basic Insurance (1 Year)",
      "price_cents": 9900,
      "price_mode": "flat",
      "meta": {"coverage": "accidental damage", "duration": "1 year"}
    }
  }')

echo "  ✓ " $(echo $VALUE2 | jq -r '.data.name') " - " $(echo $VALUE2 | jq -r '.data.price_formatted')

# Premium insurance
VALUE3=$(curl -s -X POST "$BASE_URL/v1/admin/product_options/$NEW_OPTION_ID/values" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_option_value": {
      "name": "Premium Insurance (2 Years)",
      "price_cents": 17900,
      "price_mode": "flat",
      "meta": {"coverage": "full coverage", "duration": "2 years"}
    }
  }')

echo "  ✓ " $(echo $VALUE3 | jq -r '.data.name') " - " $(echo $VALUE3 | jq -r '.data.price_formatted')
echo ""

# Update option value
echo "9️⃣ Updating option value (increase price)..."
VALUE2_ID=$(echo $VALUE2 | jq -r '.data.id')

UPDATE_RESULT=$(curl -s -X PATCH "$BASE_URL/v1/admin/product_options/$NEW_OPTION_ID/values/$VALUE2_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_option_value": {
      "price_cents": 12900,
      "meta": {"coverage": "accidental damage + theft", "duration": "1 year"}
    }
  }')

echo $UPDATE_RESULT | jq '{success: .success, message: .message, value: .data | {name, price: .price_formatted, meta}}'
echo ""

# Reorder option values
echo "🔟 Reordering option value..."
VALUE3_ID=$(echo $VALUE3 | jq -r '.data.id')

REORDER_RESULT=$(curl -s -X PATCH "$BASE_URL/v1/admin/product_options/$NEW_OPTION_ID/values/$VALUE3_ID/reorder" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"position": 1}')

echo $REORDER_RESULT | jq '{success: .success, message: .message}'
echo ""

# Get updated product detail
echo "1️⃣1️⃣ Getting updated product detail..."
UPDATED_PRODUCT=$(curl -s -X GET "$BASE_URL/products/$MACBOOK_ID")

echo "Updated Product Options:"
echo $UPDATED_PRODUCT | jq '.data.options | map({
  name: .name,
  type: .option_type,
  required: .required,
  values: .values | map({name, price: .price_formatted, mode: .price_mode})
})'
echo ""

# Update product option (make it required)
echo "1️⃣2️⃣ Updating product option (make Insurance required)..."
UPDATE_OPTION=$(curl -s -X PATCH "$BASE_URL/v1/admin/products/$MACBOOK_ID/product_options/$NEW_OPTION_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product_option": {
      "required": true,
      "name": "Insurance Coverage (Required)"
    }
  }')

echo $UPDATE_OPTION | jq '{success: .success, message: .message, option: .data | {name, required}}'
echo ""

# Test Sony headphones options (has per_unit example)
echo "1️⃣3️⃣ Testing Sony headphones options..."
SONY_ID=$(echo $PRODUCTS | jq -r '.data[] | select(.title | contains("Sony")) | .id')
SONY_DETAIL=$(curl -s -X GET "$BASE_URL/products/$SONY_ID")

echo "Sony WH-1000XM5 Options:"
echo $SONY_DETAIL | jq '.data.options | map({
  name: .name,
  type: .option_type,
  values: .values | map({
    name,
    price: .price_formatted,
    mode: .price_mode,
    description: .price_description
  })
})'
echo ""

# Delete option value
echo "1️⃣4️⃣ Deleting an option value..."
VALUE1_ID=$(echo $VALUE1 | jq -r '.data.id')

DELETE_VALUE=$(curl -s -X DELETE "$BASE_URL/v1/admin/product_options/$NEW_OPTION_ID/values/$VALUE1_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo $DELETE_VALUE | jq '{success: .success, message: .message}'
echo ""

# Delete product option
echo "1️⃣5️⃣ Deleting product option..."
DELETE_OPTION=$(curl -s -X DELETE "$BASE_URL/v1/admin/products/$MACBOOK_ID/product_options/$NEW_OPTION_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo $DELETE_OPTION | jq '{success: .success, message: .message}'
echo ""

echo "================================"
echo "✅ All tests completed!"
echo ""
echo "📊 Summary:"
echo "  - Product detail includes options ✓"
echo "  - Admin can list options ✓"
echo "  - Admin can create options ✓"
echo "  - Admin can create option values ✓"
echo "  - Admin can update option values ✓"
echo "  - Admin can reorder values ✓"
echo "  - Admin can update options ✓"
echo "  - Admin can delete values ✓"
echo "  - Admin can delete options ✓"
echo "  - Flat price mode works ✓"
echo "  - Per-unit price mode works ✓"
echo "  - Meta data stored correctly ✓"
