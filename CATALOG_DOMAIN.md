# 📦 Catalog Domain - Eksiksiz Yapı

## ✅ Oluşturulan Özellikler

### 1️⃣ **Database Schema**

#### Categories Table
```ruby
- id (integer, primary key)
- name (string, not null)
- slug (string, not null, unique, indexed)
- parent_id (integer, indexed) # Self-referential for tree structure
- created_at, updated_at
```

#### Products Table (Güncellendi)
```ruby
- id (integer, primary key)
- title (string, not null) # name'den rename edildi
- description (text)
- sku (string, not null, unique, indexed)
- price_cents (integer, not null)
- currency (string, default: 'USD')
- active (boolean, default: true, indexed)
- category_id (integer, foreign key, indexed)
- created_at, updated_at
```

#### Variants Table
```ruby
- id (integer, primary key)
- product_id (integer, not null, foreign key)
- sku (string, not null, unique, indexed)
- options (jsonb, default: {}, gin indexed) # {"color": "Red", "size": "M"}
- price_cents (integer, not null)
- currency (string, default: 'USD')
- stock (integer, default: 0)
- created_at, updated_at
```

---

### 2️⃣ **Models (app/domains/catalog/)**

#### Category Model
```ruby
# Features:
- Self-referential tree structure (parent/children)
- Automatic slug generation from name
- Validation: name presence, slug uniqueness & format
- Scopes: root_categories, active_products
- Methods: root?, leaf?, ancestors, descendants
```

**Associations:**
- `belongs_to :parent` (optional)
- `has_many :children` (dependent: destroy)
- `has_many :products` (dependent: nullify)

#### Product Model
```ruby
# Features:
- Money management (monetize price_cents)
- Automatic SKU generation
- Active/inactive status
- Category association
- Stock tracking through variants
- Search functionality

# Scopes:
- active, inactive
- in_category(id)
- search(query)
- with_stock

# Methods:
- in_stock? - Stokta var mı?
- total_stock - Toplam stok
- available_variants - Stokta olan varyantlar
```

**Associations:**
- `belongs_to :category` (optional)
- `has_many :variants` (dependent: destroy)
- `has_many :order_items` (dependent: restrict_with_error)

#### Variant Model
```ruby
# Features:
- Money management (monetize price_cents)
- Automatic SKU generation
- JSONB options field (color, size, storage, etc.)
- Stock tracking
- Validation for options (must be hash)

# Scopes:
- in_stock, out_of_stock
- by_option(key, value) # JSONB query

# Methods:
- in_stock?, out_of_stock?
- option(key) - Get option value
- set_option(key, value) - Set option value
- display_name - "Product Title (color: Red, size: M)"
```

**Associations:**
- `belongs_to :product`

---

### 3️⃣ **Serializers (JSON:API Format)**

#### CategorySerializer
```ruby
# Output format:
{
  "type": "category",
  "id": "1",
  "attributes": {
    "name": "Electronics",
    "slug": "electronics",
    "created_at": "...",
    "updated_at": "..."
  },
  "relationships": {
    "parent": { "data": { "type": "category", "id": "..." } },
    "children": { "data": [...] },
    "products": { "meta": { "count": 10 } }
  },
  "links": {
    "self": "/api/categories/1"
  }
}
```

#### ProductSerializer
```ruby
# Output format:
{
  "type": "product",
  "id": "1",
  "attributes": {
    "title": "MacBook Pro 16\"",
    "description": "...",
    "sku": "MBP-16-M2",
    "price": {
      "cents": 249999,
      "currency": "USD",
      "formatted": "$2499.99"
    },
    "active": true,
    "in_stock": true,
    "total_stock": 23,
    "created_at": "...",
    "updated_at": "..."
  },
  "relationships": {
    "category": {
      "data": { "type": "category", "id": "4" },
      "links": { "related": "/api/categories/4" }
    },
    "variants": {
      "meta": { "count": 3 },
      "links": { "related": "/api/products/1/variants" }
    }
  },
  "links": {
    "self": "/api/products/1",
    "variants": "/api/products/1/variants"
  }
}
```

#### VariantSerializer
```ruby
# Output format:
{
  "type": "variant",
  "id": "1",
  "attributes": {
    "sku": "MBP-16-M2-512GB-SILVER",
    "options": { "storage": "512GB", "color": "Silver" },
    "price": {
      "cents": 249999,
      "currency": "USD",
      "formatted": "$2499.99"
    },
    "stock": 10,
    "in_stock": true,
    "display_name": "MacBook Pro 16\" (storage: 512GB, color: Silver)",
    "created_at": "...",
    "updated_at": "..."
  },
  "relationships": {
    "product": {
      "data": { "type": "product", "id": "1" },
      "links": { "related": "/api/products/1" }
    }
  },
  "links": {
    "self": "/api/products/1/variants/1"
  }
}
```

---

### 4️⃣ **Controllers with Caching**

#### CategoriesController
**Endpoints:**
```
GET    /api/categories                    # List all (cached 1 hour)
GET    /api/categories/:id                # Show (cached 1 hour)
POST   /api/categories                    # Create (auth required)
PATCH  /api/categories/:id                # Update (auth required)
DELETE /api/categories/:id                # Delete (auth required)
GET    /api/categories/:id/products       # Category products
```

**Caching Strategy:**
- Cache key: `categories/all-{max_updated_at}`
- Expires: 1 hour
- Clears on: create, update, delete

#### ProductsController
**Endpoints:**
```
GET    /api/products                      # List all (cached 30 min)
GET    /api/products/:id                  # Show (cached 1 hour)
POST   /api/products                      # Create (auth required)
PATCH  /api/products/:id                  # Update (auth required)
DELETE /api/products/:id                  # Delete (auth required)
```

**Query Parameters:**
- `?category_id=1` - Filter by category
- `?q=laptop` - Search in title/description
- `?page=1` - Pagination (default: 1)
- `?per_page=20` - Items per page (default: 20, max: 100)

**Caching Strategy:**
- Cache key: `products/all-{cache_key_with_version}-page-{page}`
- Expires: 30 minutes
- Clears on: create, update, delete

#### VariantsController
**Endpoints:**
```
GET    /api/products/:id/variants         # List (cached 30 min)
GET    /api/products/:id/variants/:id     # Show (cached 1 hour)
POST   /api/products/:id/variants         # Create (auth required)
PATCH  /api/products/:id/variants/:id     # Update (auth required)
DELETE /api/products/:id/variants/:id     # Delete (auth required)
PATCH  /api/products/:id/variants/:id/update_stock # Update stock
```

**Query Parameters:**
- `?in_stock=true` - Only in stock
- `?out_of_stock=true` - Only out of stock
- `?option_key=color&option_value=Red` - Filter by JSONB option

**Caching Strategy:**
- Cache key: `products/{id}/variants-{max_updated_at}`
- Expires: 30 minutes
- Clears on: create, update, delete (also clears products cache)

---

### 5️⃣ **API Routes**

```ruby
# Direct API routes
/api/categories
/api/categories/:id
/api/categories/:id/products
/api/products
/api/products/:id
/api/products/:product_id/variants
/api/products/:product_id/variants/:id
/api/products/:product_id/variants/:id/update_stock

# Versioned routes (also available)
/api/v1/catalog/categories
/api/v1/catalog/products
/api/v1/catalog/products/:id/variants
```

---

## 🧪 Test Etme

### 1. Categories

**Tüm kategorileri listele:**
```bash
curl http://localhost:3000/api/categories
```

**Kategori detayı:**
```bash
curl http://localhost:3000/api/categories/1
```

**Yeni kategori oluştur (auth required):**
```bash
curl -X POST http://localhost:3000/api/categories \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": {
      "name": "Smart Home",
      "slug": "smart-home",
      "parent_id": 1
    }
  }'
```

**Kategorideki ürünler:**
```bash
curl http://localhost:3000/api/categories/4/products
```

---

### 2. Products

**Tüm ürünleri listele (with caching):**
```bash
curl http://localhost:3000/api/products
```

**Filtreleme ve arama:**
```bash
# Kategoriye göre
curl "http://localhost:3000/api/products?category_id=4"

# Arama
curl "http://localhost:3000/api/products?q=macbook"

# Pagination
curl "http://localhost:3000/api/products?page=1&per_page=10"

# Kombine
curl "http://localhost:3000/api/products?category_id=4&q=laptop&page=1"
```

**Ürün detayı (with variants):**
```bash
curl http://localhost:3000/api/products/1
```

**Yeni ürün oluştur (auth required):**
```bash
curl -X POST http://localhost:3000/api/products \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product": {
      "title": "iPhone 15 Pro",
      "description": "Latest iPhone model",
      "sku": "IPHONE-15-PRO",
      "price_cents": 99999,
      "currency": "USD",
      "active": true,
      "category_id": 1
    }
  }'
```

**Ürün güncelle:**
```bash
curl -X PATCH http://localhost:3000/api/products/1 \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product": {
      "active": false
    }
  }'
```

---

### 3. Variants

**Ürünün tüm varyantları:**
```bash
curl http://localhost:3000/api/products/1/variants
```

**Filtreler:**
```bash
# Sadece stokta olanlar
curl "http://localhost:3000/api/products/1/variants?in_stock=true"

# Belirli option'a göre
curl "http://localhost:3000/api/products/1/variants?option_key=color&option_value=Silver"
```

**Varyant detayı:**
```bash
curl http://localhost:3000/api/products/1/variants/1
```

**Yeni varyant oluştur (auth required):**
```bash
curl -X POST http://localhost:3000/api/products/1/variants \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "variant": {
      "sku": "MBP-16-M2-2TB-SILVER",
      "options": {
        "storage": "2TB",
        "color": "Silver"
      },
      "price_cents": 329999,
      "stock": 3,
      "currency": "USD"
    }
  }'
```

**Stok güncelle:**
```bash
curl -X PATCH http://localhost:3000/api/products/1/variants/1/update_stock \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "stock": 50 }'
```

---

## 📊 Seed Data

Seeds ile oluşturulan veriler:

### Categories (5)
- Electronics (root)
  - Computers
    - Laptops
  - Accessories
    - Peripherals

### Products (5)
1. **MacBook Pro 16"** (Laptops) - $2,499.99
2. **Dell XPS 15** (Laptops) - $1,799.99
3. **Logitech MX Master 3** (Peripherals) - $99.99
4. **Keychron K2** (Peripherals) - $89.99
5. **Sony WH-1000XM5** (Accessories) - $399.99

### Variants (11)
- MacBook Pro: 3 variants (storage + color options)
- Dell XPS: 2 variants (storage + RAM options)
- Logitech Mouse: 2 variants (color options)
- Keychron Keyboard: 2 variants (switch + backlight)
- Sony Headphones: 2 variants (color options)

**Toplam Stok:** 245 ürün

---

## 💾 Caching Stratejisi

### Cache Keys
```ruby
# Categories
"categories/all-{max_updated_at}"
"categories/{id}-{updated_at}"

# Products
"products/all-{cache_key_with_version}-page-{page}"
"products/{id}-{updated_at}-with-variants"

# Variants
"products/{product_id}/variants-{max_updated_at}"
"variants/{id}-{updated_at}"
```

### Cache Expiration
- Categories: 1 hour
- Products list: 30 minutes
- Product detail: 1 hour
- Variants: 30 minutes

### Cache Invalidation
- Create/Update/Delete operations automatically clear related caches
- Uses `Rails.cache.delete_matched()` for pattern-based clearing

---

## 🔒 Authorization

**Public Endpoints (No Auth):**
- GET /api/categories
- GET /api/products
- GET /api/variants

**Protected Endpoints (Auth Required):**
- POST, PATCH, DELETE operations
- Require valid JWT token in Authorization header

---

## 📝 JSON:API Features

### Error Format
```json
{
  "errors": [
    {
      "status": "422",
      "source": { "pointer": "/data/attributes/title" },
      "title": "Validation Error",
      "detail": "can't be blank"
    }
  ]
}
```

### Collection Format
```json
{
  "data": [...],
  "meta": {
    "total": 10,
    "cached_at": "2025-10-10T22:15:30Z"
  }
}
```

### Single Resource Format
```json
{
  "data": {
    "type": "product",
    "id": "1",
    "attributes": {...},
    "relationships": {...},
    "links": {...}
  }
}
```

---

## ✅ Özellikler Özeti

1. ✅ **Category Model** - Tree structure with parent/children
2. ✅ **Product Model** - With category association & variants
3. ✅ **Variant Model** - JSONB options, stock tracking
4. ✅ **Automatic SKU Generation** - For products & variants
5. ✅ **Money Management** - Monetize gem integration
6. ✅ **Caching** - Rails.cache with smart invalidation
7. ✅ **JSON:API Format** - Standardized response format
8. ✅ **Search & Filters** - Query, category, stock filters
9. ✅ **Pagination** - For product listings
10. ✅ **JSONB Queries** - Filter variants by options
11. ✅ **Stock Tracking** - Inventory management
12. ✅ **Nested Routes** - /products/:id/variants
13. ✅ **Comprehensive Seeds** - Real-world test data
14. ✅ **Error Handling** - JSON:API error format
15. ✅ **Authorization** - Protected create/update/delete

---

## 🚀 Next Steps (Opsiyonel)

1. **Image Upload** - ActiveStorage ile ürün resimleri
2. **Elasticsearch** - Gelişmiş arama
3. **Product Reviews** - Yorum ve değerlendirme sistemi
4. **Price History** - Fiyat geçmişi tracking
5. **Bulk Operations** - Toplu ürün import/export
6. **Product Bundles** - Ürün paketleri
7. **Related Products** - İlişkili ürün önerileri
8. **Inventory Alerts** - Düşük stok uyarıları
9. **Product Attributes** - Dinamik özellik sistemi
10. **SEO Optimization** - Meta tags, sitemaps

---

**Catalog domain kullanıma hazır! 🎉**
