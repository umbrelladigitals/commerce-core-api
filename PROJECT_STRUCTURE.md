# Commerce Core API - Proje Yapısı

## Oluşturulan Dosyalar ve Yapı

### 📁 Domain Yapısı (app/domains)

```
app/domains/
├── users/
│   ├── controllers/
│   │   ├── base_controller.rb
│   │   └── profiles_controller.rb
│   ├── models/
│   ├── policies/
│   │   └── user_policy.rb
│   └── services/
│
├── catalog/
│   ├── controllers/
│   │   ├── base_controller.rb
│   │   └── products_controller.rb
│   ├── models/
│   │   └── product.rb
│   ├── policies/
│   └── services/
│
└── orders/
    ├── controllers/
    │   ├── base_controller.rb
    │   └── orders_controller.rb
    ├── models/
    │   ├── order.rb
    │   └── order_item.rb
    ├── policies/
    │   └── order_policy.rb
    └── services/
```

### 📁 API Controllers (app/controllers/api/v1)

```
app/controllers/api/v1/
├── base_controller.rb
├── users/
│   └── profiles_controller.rb
├── catalog/
│   └── products_controller.rb
└── orders/
    └── orders_controller.rb
```

### 📁 Devise Controllers (app/controllers/users)

```
app/controllers/users/
├── sessions_controller.rb       # Login/Logout
└── registrations_controller.rb  # Signup
```

### 📁 Models

```
app/models/
├── application_record.rb
├── user.rb                      # Devise + JWT
└── jwt_denylist.rb             # JWT token revocation
```

### 📁 Jobs

```
app/jobs/
├── application_job.rb
└── orders/
    └── order_confirmation_job.rb  # Sidekiq background job
```

### 📁 Policies

```
app/policies/
└── application_policy.rb          # Pundit base policy
```

### 📁 Configuration Files

```
config/
├── application.rb                 # Autoload paths, Sidekiq config
├── routes.rb                      # API routes, Swagger, Sidekiq UI
├── database.yml                   # PostgreSQL config
│
├── initializers/
│   ├── cors.rb                    # CORS configuration
│   ├── devise.rb                  # Devise configuration
│   ├── devise_jwt.rb              # JWT configuration
│   ├── money.rb                   # Money-rails configuration
│   ├── sidekiq.rb                 # Sidekiq/Redis configuration
│   ├── rswag_api.rb              # Swagger API config
│   └── rswag_ui.rb               # Swagger UI config
```

### 📁 Database Migrations

```
db/migrate/
├── *_devise_create_users.rb      # Users table
├── *_create_jwt_denylists.rb     # JWT denylist table
├── *_create_products.rb          # Products table
├── *_create_orders.rb            # Orders table
└── *_create_order_items.rb       # Order items table
```

### 📁 Tests (RSpec)

```
spec/
├── spec_helper.rb
├── rails_helper.rb
├── swagger_helper.rb              # Rswag configuration
├── requests/
│   └── api/v1/catalog/
│       └── products_spec.rb       # API tests & Swagger docs
├── models/
│   ├── user_spec.rb
│   └── jwt_denylist_spec.rb
└── factories/
    ├── users.rb
    └── jwt_denylists.rb
```

### 📁 Swagger Documentation

```
swagger/
└── v1/
    └── swagger.yaml               # Generated Swagger documentation
```

## 🎯 Özellikler

### ✅ Authentication (Devise + JWT)
- User registration/signup: `POST /signup`
- User login: `POST /login`
- User logout: `DELETE /logout`
- JWT token based authentication
- Token revocation strategy (denylist)

### ✅ Authorization (Pundit)
- Policy-based authorization
- UserPolicy: Kullanıcı profil yetkileri
- OrderPolicy: Sipariş yetkileri

### ✅ Money Management (Money-Rails)
- Para/currency yönetimi
- Monetize ile price_cents alanları
- Multi-currency desteği

### ✅ Background Jobs (Sidekiq + Redis)
- OrderConfirmationJob örnek job
- Sidekiq dashboard: http://localhost:3000/sidekiq

### ✅ API Documentation (Rswag)
- Swagger/OpenAPI documentation
- Swagger UI: http://localhost:3000/api-docs
- RSpec ile entegre test ve dokümantasyon

### ✅ CORS Support
- Rack-CORS ile cross-origin desteği
- Production için yapılandırılabilir

### ✅ Testing (RSpec)
- RSpec test framework
- Factory Bot ile test data
- Faker ile fake data
- Rswag ile API test specs

## 🔌 API Endpoints

### Authentication
```
POST   /signup                                    # Kullanıcı kaydı
POST   /login                                     # Kullanıcı girişi
DELETE /logout                                    # Kullanıcı çıkışı
```

### Users Domain
```
GET    /api/v1/users/profile                     # Profil görüntüle
PATCH  /api/v1/users/profile                     # Profil güncelle
```

### Catalog Domain
```
GET    /api/v1/catalog/products                  # Ürünleri listele
POST   /api/v1/catalog/products                  # Ürün oluştur
GET    /api/v1/catalog/products/:id              # Ürün detayı
PATCH  /api/v1/catalog/products/:id              # Ürün güncelle
DELETE /api/v1/catalog/products/:id              # Ürün sil
```

### Orders Domain
```
GET    /api/v1/orders/orders                     # Siparişleri listele
POST   /api/v1/orders/orders                     # Sipariş oluştur
GET    /api/v1/orders/orders/:id                 # Sipariş detayı
PATCH  /api/v1/orders/orders/:id                 # Sipariş güncelle
PATCH  /api/v1/orders/orders/:id/cancel          # Sipariş iptal
```

### Other
```
GET    /up                                        # Health check
GET    /api-docs                                  # Swagger UI
GET    /sidekiq                                   # Sidekiq dashboard
```

## 📦 Gem'ler

### Core
- rails (~> 7.2.2)
- pg (~> 1.1) - PostgreSQL
- puma (>= 5.0) - Web server

### Authentication & Authorization
- devise - Authentication
- devise-jwt - JWT tokens
- pundit - Authorization

### Money & Background Jobs
- money-rails - Money management
- sidekiq - Background jobs
- redis (>= 4.0.1) - Redis client

### API & Documentation
- rswag - Swagger/OpenAPI
- rswag-api - API runtime
- rswag-ui - Swagger UI
- rack-cors - CORS support

### Development & Testing
- rspec-rails - Testing framework
- factory_bot_rails - Test factories
- faker - Fake data
- rswag-specs - API specs
- brakeman - Security scanner
- debug - Debugging
- rubocop-rails-omakase - Code style

## 🚀 Çalıştırma

### Gereksinimler
1. PostgreSQL
2. Redis
3. Ruby 3.1.0+

### Kurulum ve Başlatma
```bash
# 1. Bağımlılıkları yükle
bundle install

# 2. Veritabanını oluştur
rails db:create db:migrate db:seed

# 3. Redis'i başlat (yeni terminal)
redis-server

# 4. Sidekiq'i başlat (yeni terminal)
bundle exec sidekiq

# 5. Rails'i başlat
rails server
```

### Test
```bash
# Tüm testleri çalıştır
bundle exec rspec

# Swagger dokümantasyonunu güncelle
rake rswag:specs:swaggerize
```

## 📚 Dokümantasyon

- **README.md** - Genel proje dokümantasyonu
- **SETUP.md** - Detaylı kurulum talimatları (Türkçe)
- **swagger/v1/swagger.yaml** - API dokümantasyonu
- http://localhost:3000/api-docs - Swagger UI

## 🎨 Mimari Kararlar

1. **Domain-Driven Design**: Modüler yapı için app/domains kullanımı
2. **API-Only Mode**: Frontend'den bağımsız backend
3. **JWT Authentication**: Stateless authentication
4. **Policy-Based Authorization**: Pundit ile temiz yetkilendirme
5. **Money Object Pattern**: Para yönetimi için money-rails
6. **Background Processing**: Async işler için Sidekiq
7. **API Documentation**: Rswag ile otomatik dokümantasyon

## 📝 Notlar

- Tüm domain'ler `app/domains` altında organize edilmiştir
- API versiyonu v1 olarak tanımlanmıştır
- CORS tüm origin'lere açıktır (production'da güncellenmeli)
- JWT secret key environment variable'dan okunur
- Money management için currency desteği mevcuttur
- Background job'lar için Sidekiq kullanılmaktadır
