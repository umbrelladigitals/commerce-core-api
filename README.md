# Commerce Core API

Rails 8 API-only e-commerce backend with JWT authentication, domain-driven design, and comprehensive caching.

## 🚀 Quick Start

```bash
# Install dependencies
bundle install

# Setup database
rails db:create db:migrate **See [ORDERS_DOMAIN.md](ORDERS_DOMAIN.md) for detailed documentation**

## 💼 B2B (Business-to-Business)

### Dealer Features

Dealers get special pricing and account management:

- **Product Discounts:** 0-100% configurable per product
- **Lower Free Shipping:** $100 threshold (vs $2**See [PAYTR_INTEGRATION.md](PAYTR_INTEGRATION.md) for detailed documentation**
**Quick start: [PAYTR_QUICKSTART.md](PAYTR_QUICKSTART.md)**

## 👨‍💼 Admin Panel

### Admin Features

Administrators can manage the entire system through RESTful API endpoints:

- **Order Management:** Create orders on behalf of customers/dealers
- **Admin Notes:** Add notes to orders, customers, quotes
- **Quotes/Proforma:** Create and manage quotes, convert to orders
- **Full Control:** View, update, and manage all system resources

#### Quick Test

```bash
./test_admin_api.sh
```

**See [ADMIN_PANEL_API.md](ADMIN_PANEL_API.md) for detailed documentation**

## 📚 Domain Documentationor customers)
- **Credit Accounts:** Balance tracking with credit limits
- **Flexible Payments:** Pay with account balance

### B2B Endpoints

```bash
# Dealer Discounts
GET    /api/v1/b2b/dealer_discounts           # List discounts
POST   /api/v1/b2b/dealer_discounts           # Create discount (admin)
PATCH  /api/v1/b2b/dealer_discounts/:id       # Update discount (admin)
DELETE /api/v1/b2b/dealer_discounts/:id       # Delete discount (admin)

# Dealer Balances
GET    /api/v1/b2b/my_balance                 # View own balance (dealer)
GET    /api/v1/b2b/dealer_balances            # List all balances (admin)
POST   /api/v1/b2b/dealer_balances/:id/add_credit      # Add credit (admin)
PATCH  /api/v1/b2b/dealer_balances/:id/update_credit_limit  # Update limit (admin)
```

### Automatic Dealer Pricing

OrderPriceCalculator automatically applies:
- Product-specific discounts
- Dealer shipping threshold ($100)
- Tax calculation on discounted prices
- Balance checking and deduction

**See [B2B_DOMAIN.md](B2B_DOMAIN.md) for detailed documentation**

## 💾 Caching Strategyseed

# Start Redis (for Sidekiq and caching)
redis-server

# Start Sidekiq (in another terminal)
bundle exec sidekiq

# Start Rails server
rails server

# Test the API
./test_api.sh
```

## 📋 Tech Stack

- **Framework:** Ruby on Rails 8 (API-only)
- **Ruby Version:** 3.1.0
- **Database:** PostgreSQL with JSONB support
- **Authentication:** Devise + Devise-JWT
- **Authorization:** Pundit (policy-based)
- **Background Jobs:** Sidekiq + Redis
- **Caching:** Rails.cache with Redis
- **Money Handling:** Money-Rails with monetize
- **API Documentation:** Rswag (Swagger/OpenAPI)
- **CORS:** Rack-CORS
- **Testing:** RSpec + Factory Bot + Faker

## 🏗️ Architecture

### Domain-Driven Design Structure

```
app/
├── domains/
│   ├── catalog/
│   │   ├── category.rb           # Tree structure with parent/children
│   │   ├── product.rb            # Main product with variants & options
│   │   ├── variant.rb            # Product variants with JSONB options
│   │   ├── product_option.rb     # Product customization options
│   │   └── product_option_value.rb  # Option values with pricing
│   ├── orders/
│   │   ├── order.rb              # Customer orders with status enum
│   │   └── order_line.rb         # Order line items with price calculation
│   ├── b2b/
│   │   ├── dealer_discount.rb    # Dealer product discounts
│   │   └── dealer_balance.rb     # Dealer account balance
│   └── users/                    # (User model in app/models for Devise)
├── serializers/
│   └── catalog/                  # JSON:API compliant serializers
├── controllers/
│   └── api/v1/
│       ├── catalog/         # Catalog API controllers
│       └── b2b/             # B2B API controllers
└── policies/
    └── catalog/             # Pundit authorization policies
```

## 📦 Catalog Domain

### Models

**Category** - Hierarchical product categorization
- Tree structure with parent/children relationships
- Auto-generated slugs for SEO-friendly URLs
- Methods: `root?`, `leaf?`, `ancestors`, `descendants`

**Product** - Core product information
- Belongs to category
- Has many variants and product options
- Monetize integration for price handling
- Scopes: `active`, `in_category`, `search`, `with_stock`
- Methods: `in_stock?`, `total_stock`, `available_variants`, `has_options?`, `options_with_values`

**Variant** - Product variations with flexible attributes
- JSONB options field for dynamic attributes (color, size, etc.)
- Individual SKU, pricing, and stock tracking
- Monetize integration
- Scopes: `in_stock`, `by_option`

**ProductOption** - Customizable product options
- Types: select, radio, checkbox, color
- Required or optional selections
- Position-based ordering
- Methods: `display_name`, `price_range`, `cheapest_value`, `most_expensive_value`

**ProductOptionValue** - Option choices with pricing
- **Flat pricing:** Fixed price added once (warranty, gift wrap)
- **Per-unit pricing:** Price multiplied by quantity (batteries, cables)
- Meta data support (JSONB) for custom attributes
- Methods: `calculate_price(qty)`, `price_description`, `display_name`
- Methods: `option(key)`, `set_option(key, value)`, `display_name`

### API Endpoints

#### Categories
```bash
GET    /api/categories              # List all categories (cached 1hr)
GET    /api/categories/:id          # Get category details
GET    /api/categories/:id/products # Get category products
POST   /api/categories              # Create category (auth required)
PATCH  /api/categories/:id          # Update category (auth required)
DELETE /api/categories/:id          # Delete category (auth required)
```

#### Products
```bash
GET    /api/products                # List products (cached 30min, paginated)
GET    /api/products/:id            # Get product details
POST   /api/products                # Create product (auth required)
PATCH  /api/products/:id            # Update product (auth required)
DELETE /api/products/:id            # Delete product (auth required)

# Query parameters
?category_id=1                      # Filter by category
?q=laptop                           # Search in title/description
?page=2                             # Pagination
```

#### Variants
```bash
GET    /api/products/:product_id/variants              # List variants (cached 30min)
GET    /api/products/:product_id/variants/:id         # Get variant details
POST   /api/products/:product_id/variants             # Create variant (auth required)
PATCH  /api/products/:product_id/variants/:id         # Update variant (auth required)
DELETE /api/products/:product_id/variants/:id         # Delete variant (auth required)
PATCH  /api/products/:product_id/variants/:id/update_stock  # Update stock (auth required)

# Query parameters
?in_stock=true                      # Filter by stock status
?option_key=color&option_value=Red  # Filter by JSONB option
```

#### Product Options (Admin)
```bash
# Options
GET    /api/v1/admin/products/:product_id/product_options      # List options
GET    /api/v1/admin/products/:product_id/product_options/:id  # Get option
POST   /api/v1/admin/products/:product_id/product_options      # Create option
PATCH  /api/v1/admin/products/:product_id/product_options/:id  # Update option
DELETE /api/v1/admin/products/:product_id/product_options/:id  # Delete option
PATCH  /api/v1/admin/products/:product_id/product_options/:id/reorder  # Reorder

# Option Values
GET    /api/v1/admin/product_options/:option_id/values      # List values
GET    /api/v1/admin/product_options/:option_id/values/:id  # Get value
POST   /api/v1/admin/product_options/:option_id/values      # Create value
PATCH  /api/v1/admin/product_options/:option_id/values/:id  # Update value
DELETE /api/v1/admin/product_options/:option_id/values/:id  # Delete value
PATCH  /api/v1/admin/product_options/:option_id/values/:id/reorder  # Reorder
```

**Note:** Product detail endpoint (`GET /api/products/:id`) automatically includes options and values for frontend consumption.

### JSON:API Response Format

All catalog endpoints return JSON:API compliant responses:

```json
{
  "data": {
    "type": "products",
    "id": "1",
    "attributes": {
      "title": "MacBook Pro",
      "description": "High-performance laptop",
      "sku": "MBP-001",
      "price": "$2,999.00",
      "currency": "USD",
      "active": true
    },
    "relationships": {
      "category": {
        "data": { "type": "categories", "id": "4" }
      },
      "variants": {
        "data": [
          { "type": "variants", "id": "1" },
          { "type": "variants", "id": "2" }
        ]
      }
    },
    "links": {
      "self": "/api/products/1",
      "category": "/api/categories/4",
      "variants": "/api/products/1/variants"
    }
  }
}
```

## 🔐 Authentication

### User Roles

- `customer` (default) - Regular customers
- `admin` - Full system access
- `dealer` - B2B dealer accounts
- `manufacturer` - Product suppliers
- `marketer` - Marketing team access

### Endpoints

```bash
POST /users                  # Sign up
POST /users/sign_in          # Login (returns JWT in Authorization header)
DELETE /users/sign_out       # Logout (revokes JWT)
```

### Using JWT Token

```bash
# Login and capture token from header
curl -i -X POST http://localhost:3000/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"admin@example.com","password":"password123"}}'

# Use token in subsequent requests
curl -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  http://localhost:3000/api/products
```

## � Orders & Cart

### Order Status Flow

```
cart → paid → shipped
  ↓      ↓
  cancelled
```

### Cart Endpoints

```bash
GET    /api/cart                    # View cart
POST   /api/cart/add                # Add item to cart
POST   /api/cart/checkout           # Start checkout process
PATCH  /api/cart/items/:id          # Update item quantity
DELETE /api/cart/items/:id          # Remove item from cart
DELETE /api/cart/clear              # Clear cart
```

### Payment Endpoints

```bash
POST   /api/payment/confirm         # Confirm payment (manual/test)
POST   /api/payment/webhook         # Stripe webhook handler
```

### OrderPriceCalculator Service

Automatically calculates:
- **Subtotal:** Sum of all order lines
- **Shipping:** $30 (FREE over $200)
- **Tax (KDV):** 18% on subtotal + shipping
- **Total:** Subtotal + Shipping + Tax

### Background Jobs

- `OrderConfirmationJob` - Sends confirmation email after payment
  - Retries: 3 attempts with 5 second delay
  - Logs order details to console
  - Can be extended for SMS/push notifications

**See [ORDERS_DOMAIN.md](ORDERS_DOMAIN.md) for detailed documentation**

## �💾 Caching Strategy

### Cache Keys & Expiration

- **Categories:** `categories/all-{timestamp}` - 1 hour
- **Products:** `products/all-{version}-page-{n}` - 30 minutes
- **Variants:** `variants/{product_id}-{timestamp}` - 30 minutes

### Cache Invalidation

- Automatic on create/update/delete operations
- Uses `delete_matched` for pattern-based invalidation
- Smart timestamp-based cache busting

## 🧪 Testing

### Run Tests

```bash
# Run all specs
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/models/catalog/product_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### API Testing Scripts

```bash
# Test catalog endpoints (products, categories, variants)
./test_api.sh

# Test orders & cart endpoints
./test_orders_api.sh

# Test B2B endpoints (dealer discounts, balances)
./test_b2b_api.sh

# Test on custom port
./test_api.sh 3001
```

## 📊 Seed Data

The database seeds include:

- **5 Users:** admin, customer, dealer, manufacturer, marketer
- **5 Categories:** Electronics → Computers → Laptops, Peripherals, Accessories
- **5 Products:** MacBook Pro, Dell XPS, Logitech Mouse, Keychron Keyboard, Sony Headphones
- **11 Variants:** Different configurations (storage, color, RAM, switches)
- **7 Product Options:** Warranty, Engraving, Gift Wrapping, Carrying Case, Extra Keycaps, USB Cable, Extra Batteries
- **19 Option Values:** Various choices with flat/per-unit pricing
- **2 Sample Orders:** 
  - Active cart (customer) - $3,200
  - Paid order (dealer) - $670
- **B2B Data:**
  - 1 Dealer balance ($500 balance, $1,000 credit limit)
  - 4 Dealer discounts (10-20% on various products)

```bash
rails db:seed
```

## 📝 API Documentation

### Swagger UI

After starting the server, visit:

```
http://localhost:3000/api-docs
```

### Generate Swagger JSON

```bash
rake rswag:specs:swaggerize
```

## Setup

### Prerequisites

- Ruby 3.1.0 or higher
- PostgreSQL
- Redis (for Sidekiq)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```

3. Setup database:
   ```bash
   rails db:create
   rails db:migrate
   ```

4. Start Redis (in a separate terminal):
   ```bash
   redis-server
   ```

5. Start Sidekiq (in a separate terminal):
   ```bash
   bundle exec sidekiq
   ```

6. Start Rails server:
   ```bash
   rails server
   ```

## API Documentation

Once the server is running, access the Swagger documentation at:
- **Swagger UI**: http://localhost:3000/api-docs

## API Endpoints

### Authentication
- `POST /signup` - User registration
- `POST /login` - User login (returns JWT token)
- `DELETE /logout` - User logout

### Users
- `GET /api/v1/users/profile` - Get current user profile
- `PATCH /api/v1/users/profile` - Update current user profile

### Catalog
- `GET /api/v1/catalog/products` - List all products
- `GET /api/v1/catalog/products/:id` - Get product details
- `POST /api/v1/catalog/products` - Create product
- `PATCH /api/v1/catalog/products/:id` - Update product
- `DELETE /api/v1/catalog/products/:id` - Delete product

### Orders
- `GET /api/v1/orders/orders` - List user's orders
- `GET /api/v1/orders/orders/:id` - Get order details
- `POST /api/v1/orders/orders` - Create order
- `PATCH /api/v1/orders/orders/:id` - Update order
- `PATCH /api/v1/orders/orders/:id/cancel` - Cancel order

## Authentication

The API uses JWT tokens for authentication. Include the token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## Environment Variables

Create a `.env` file with the following variables:

```env
DATABASE_URL=postgresql://localhost/commerce_core_api_development
REDIS_URL=redis://localhost:6379/0
DEVISE_JWT_SECRET_KEY=your_secret_key_here
```

## Testing

Run the test suite:

```bash
bundle exec rspec
```

## Background Jobs

Sidekiq is used for background job processing. Access the Sidekiq dashboard at:
- http://localhost:3000/sidekiq

## � Payment Integration

### PayTR (Turkish Payment Gateway)

Integrated payment processing with PayTR:

```bash
# Environment setup
PAYTR_MERCHANT_ID=your_merchant_id
PAYTR_MERCHANT_KEY=your_merchant_key
PAYTR_MERCHANT_SALT=your_merchant_salt
PAYTR_CALLBACK_URL=https://yourdomain.com/api/payment
```

#### Payment Flow

1. Customer adds items to cart
2. POST `/api/cart/checkout` → Returns PayTR token & iframe URL
3. Frontend displays payment iframe or redirects
4. Customer completes payment on PayTR
5. PayTR sends callback to `/api/payment/paytr/callback`
6. Order status updated to `paid`
7. Confirmation email sent automatically

#### Quick Test

```bash
./test_paytr_api.sh
```

**See [PAYTR_INTEGRATION.md](PAYTR_INTEGRATION.md) for detailed documentation**
**Quick start: [PAYTR_QUICKSTART.md](PAYTR_QUICKSTART.md)**

## �📚 Domain Documentation

Detailed documentation for each domain:

- **[Catalog Domain](CATALOG_DOMAIN.md)** - Products, categories, variants, caching
- **[Product Options](PRODUCT_OPTIONS_DOMAIN.md)** - Customizable options, flat/per-unit pricing
- **[Orders Domain](ORDERS_DOMAIN.md)** - Cart, checkout, payments, order management
- **[B2B Domain](B2B_DOMAIN.md)** - Dealer discounts, balances, credit management
- **[PayTR Payment](PAYTR_INTEGRATION.md)** - Payment gateway integration, callbacks, security
- **[Admin Panel](ADMIN_PANEL_API.md)** - Order creation, notes, quotes/proforma management

## Domain Structure

Each domain is self-contained with its own:
- **Models**: Business entities
- **Controllers**: API endpoints
- **Policies**: Authorization rules (using Pundit)
- **Services**: Business logic (e.g., OrderPriceCalculator)

## Development

### Adding a New Domain

1. Create domain structure:
   ```bash
   mkdir -p app/domains/your_domain/{models,controllers,policies,services}
   ```

2. Create models, controllers, and policies following the existing domain patterns

3. Add routes in `config/routes.rb`

### Code Quality

The project uses RuboCop for code style enforcement:

```bash
bundle exec rubocop
```

### Test Scripts

Comprehensive API test scripts are available:

```bash
# General API tests
./test_api.sh

# B2B specific tests (dealer discounts, balances)
./test_b2b_api.sh

# Product options tests (admin CRUD, frontend integration)
./test_product_options_api.sh
```

## License

This project is licensed under the MIT License.
