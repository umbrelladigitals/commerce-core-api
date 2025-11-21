#!/bin/bash

# Commerce Core API Test Script
# Usage: ./test_api.sh [port]
# Default port: 3000

PORT=${1:-3000}
BASE_URL="http://localhost:${PORT}"

echo "🔍 Testing Commerce Core API at ${BASE_URL}"
echo "================================================"
echo ""

# Test 1: Categories
echo "📁 Test 1: Get all categories"
echo "GET ${BASE_URL}/api/categories"
curl -s "${BASE_URL}/api/categories" | jq '.'
echo ""
echo ""

# Test 2: Single category with products
echo "📁 Test 2: Get category with products"
echo "GET ${BASE_URL}/api/categories/4/products"
curl -s "${BASE_URL}/api/categories/4/products" | jq '.'
echo ""
echo ""

# Test 3: All products
echo "📦 Test 3: Get all products"
echo "GET ${BASE_URL}/api/products"
curl -s "${BASE_URL}/api/products" | jq '.data[] | {id: .id, title: .attributes.title, price: .attributes.price}'
echo ""
echo ""

# Test 4: Products with filters
echo "📦 Test 4: Search products (query: 'laptop')"
echo "GET ${BASE_URL}/api/products?q=laptop"
curl -s "${BASE_URL}/api/products?q=laptop" | jq '.data[] | {id: .id, title: .attributes.title}'
echo ""
echo ""

# Test 5: Single product
echo "📦 Test 5: Get single product"
echo "GET ${BASE_URL}/api/products/1"
curl -s "${BASE_URL}/api/products/1" | jq '.'
echo ""
echo ""

# Test 6: Product variants
echo "🎨 Test 6: Get product variants"
echo "GET ${BASE_URL}/api/products/1/variants"
curl -s "${BASE_URL}/api/products/1/variants" | jq '.data[] | {id: .id, name: .attributes.display_name, price: .attributes.price, stock: .attributes.stock}'
echo ""
echo ""

# Test 7: Single variant
echo "🎨 Test 7: Get single variant"
echo "GET ${BASE_URL}/api/products/1/variants/1"
curl -s "${BASE_URL}/api/products/1/variants/1" | jq '.'
echo ""
echo ""

# Test 8: Filter variants by option
echo "🎨 Test 8: Filter variants by color"
echo "GET ${BASE_URL}/api/products/1/variants?option_key=color&option_value=Silver"
curl -s "${BASE_URL}/api/products/1/variants?option_key=color&option_value=Silver" | jq '.data[] | {id: .id, name: .attributes.display_name, options: .attributes.options}'
echo ""
echo ""

# Test 9: User signup
echo "👤 Test 9: User signup"
echo "POST ${BASE_URL}/users"
curl -s -X POST "${BASE_URL}/users" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "testuser@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "name": "Test User"
    }
  }' | jq '.'
echo ""
echo ""

# Test 10: User login
echo "🔐 Test 10: User login"
echo "POST ${BASE_URL}/users/sign_in"
TOKEN_RESPONSE=$(curl -s -X POST "${BASE_URL}/users/sign_in" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@example.com",
      "password": "password123"
    }
  }')
echo "${TOKEN_RESPONSE}" | jq '.'

# Extract token from response header (if present)
TOKEN=$(echo "${TOKEN_RESPONSE}" | jq -r '.token // empty')
if [ -z "$TOKEN" ]; then
  echo "⚠️  Note: Token might be in response headers (Authorization header)"
fi
echo ""
echo ""

echo "✅ All tests completed!"
echo ""
echo "📝 Notes:"
echo "  - Caching is enabled (Categories: 1hr, Products: 30min, Variants: 30min)"
echo "  - JWT token is returned in the Authorization header on login"
echo "  - Use the token for authenticated endpoints (create/update/delete)"
echo "  - Install jq for pretty JSON output: sudo apt-get install jq"
