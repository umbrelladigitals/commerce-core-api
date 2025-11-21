#!/bin/bash

BASE_URL="http://localhost:3000"

echo "=== Bank Accounts API Test ==="
echo ""

# Admin login
echo "1. Admin login..."
ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@example.com",
      "password": "password123"
    }
  }' | jq -r '.token')

if [ -z "$ADMIN_TOKEN" ] || [ "$ADMIN_TOKEN" == "null" ]; then
  echo "❌ Admin login failed"
  exit 1
fi
echo "✅ Admin token: ${ADMIN_TOKEN:0:20}..."
echo ""

# Create bank account
echo "2. Creating bank account..."
RESPONSE=$(curl -s -X POST "$BASE_URL/api/admin/bank_accounts" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bank_name": "Ziraat Bankası",
    "iban": "TR330006100519786457841326",
    "account_holder": "ABC Ticaret Ltd. Şti.",
    "branch": "Ankara Çankaya Şubesi",
    "account_number": "19786457"
  }')

echo "$RESPONSE" | jq '.'
ACCOUNT_ID=$(echo "$RESPONSE" | jq -r '.data.id')
echo ""

# Create second account
echo "3. Creating second bank account..."
curl -s -X POST "$BASE_URL/api/admin/bank_accounts" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bank_name": "İş Bankası",
    "iban": "TR640006400000111222333444",
    "account_holder": "ABC Ticaret Ltd. Şti.",
    "branch": "İstanbul Şişli Şubesi",
    "account_number": "111222333"
  }' | jq '.'
echo ""

# List accounts (admin)
echo "4. Listing bank accounts (Admin)..."
curl -s -X GET "$BASE_URL/api/admin/bank_accounts" \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'
echo ""

# List accounts (public)
echo "5. Listing bank accounts (Public - for payment page)..."
curl -s -X GET "$BASE_URL/api/v1/bank_accounts" | jq '.'
echo ""

# Update account
if [ ! -z "$ACCOUNT_ID" ] && [ "$ACCOUNT_ID" != "null" ]; then
  echo "6. Updating bank account..."
  curl -s -X PUT "$BASE_URL/api/admin/bank_accounts/$ACCOUNT_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "bank_name": "Ziraat Bankası",
      "branch": "Ankara Kızılay Şubesi"
    }' | jq '.'
  echo ""
  
  # Delete account
  echo "7. Deleting bank account..."
  curl -s -X DELETE "$BASE_URL/api/admin/bank_accounts/$ACCOUNT_ID" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'
  echo ""
  
  # List again
  echo "8. Final list..."
  curl -s -X GET "$BASE_URL/api/admin/bank_accounts" \
    -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.'
fi

echo ""
echo "=== Test completed ==="
