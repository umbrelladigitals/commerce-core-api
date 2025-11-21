# Commerce Core API - Setup Instructions

## Proje Özellikleri

Bu proje aşağıdaki özelliklere sahiptir:

✅ Rails 8 API-only mode
✅ PostgreSQL veritabanı
✅ Devise + Devise-JWT ile authentication
✅ Pundit ile authorization
✅ Money-Rails ile para yönetimi
✅ Sidekiq + Redis ile background işler
✅ Rswag ile Swagger API dokümantasyonu
✅ Rack-CORS ile CORS desteği
✅ RSpec ile test altyapısı
✅ Modüler domain yapısı (app/domains)

## Kurulum Adımları

### 1. Bağımlılıkları Yükle
```bash
cd commerce_core_api
bundle install
```

### 2. Veritabanını Oluştur ve Migrate Et
```bash
rails db:create
rails db:migrate
rails db:seed  # Örnek veriler için (opsiyonel)
```

### 3. Redis'i Başlat
Yeni bir terminal penceresinde:
```bash
redis-server
```

### 4. Sidekiq'i Başlat
Yeni bir terminal penceresinde:
```bash
cd commerce_core_api
bundle exec sidekiq
```

### 5. Rails Sunucusunu Başlat
```bash
rails server
```

## Test Etme

### Kullanıcı Kayıt (Signup)
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

### Kullanıcı Giriş (Login)
```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123"
    }
  }'
```

Response'dan gelen `Authorization` header'ındaki JWT token'ı kaydedin.

### Ürünleri Listele
```bash
curl http://localhost:3000/api/v1/catalog/products
```

### Profil Bilgilerini Görüntüle (JWT Token Gerekli)
```bash
curl http://localhost:3000/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## API Dokümantasyonu

Swagger UI'ye erişim:
- http://localhost:3000/api-docs

## Sidekiq Dashboard

Sidekiq dashboard'una erişim:
- http://localhost:3000/sidekiq

## Domain Yapısı

Proje üç ana domain'e ayrılmıştır:

### 1. Users Domain
- Kullanıcı yönetimi
- Profil işlemleri
- Authentication & Authorization

### 2. Catalog Domain
- Ürün yönetimi
- Ürün listeleme ve detayları

### 3. Orders Domain
- Sipariş yönetimi
- Sipariş oluşturma ve takibi
- Sipariş iptali

Her domain kendi içinde:
- `models/` - Veri modelleri
- `controllers/` - API endpoint'leri
- `policies/` - Yetkilendirme kuralları
- `services/` - İş mantığı

## Yapılandırma

### Environment Variables

`.env` dosyası oluşturun (`.env.example` dosyasını kopyalayın):

```bash
cp .env.example .env
```

Ve gerekli değerleri güncelleyin:
```
DATABASE_URL=postgresql://localhost/commerce_core_api_development
REDIS_URL=redis://localhost:6379/0
DEVISE_JWT_SECRET_KEY=your_secret_key_here
```

### JWT Secret Key

Production ortamında JWT secret key'i `rails credentials:edit` ile yönetin:

```bash
EDITOR="code --wait" rails credentials:edit
```

Ve ekleyin:
```yaml
devise_jwt_secret_key: your_generated_secret_key
```

## Testler

RSpec testlerini çalıştırın:

```bash
bundle exec rspec
```

## Yeni Domain Ekleme

1. Domain yapısını oluşturun:
```bash
mkdir -p app/domains/yeni_domain/{models,controllers,policies,services}
```

2. Model, controller ve policy dosyalarını oluşturun

3. `config/routes.rb` dosyasına route'ları ekleyin

## Notlar

- PostgreSQL'in kurulu ve çalışır durumda olması gerekiyor
- Redis'in kurulu ve çalışır durumda olması gerekiyor (Sidekiq için)
- Ruby 3.1.0 veya üzeri gereklidir

## Sorun Giderme

### Nokogiri Hatası
Eğer nokogiri kurulum hatası alırsanız:
```bash
bundle config build.nokogiri --use-system-libraries
bundle install
```

### PostgreSQL Bağlantı Hatası
PostgreSQL'in çalıştığından emin olun:
```bash
sudo service postgresql start  # Linux
brew services start postgresql # macOS
```

### Redis Bağlantı Hatası
Redis'in çalıştığından emin olun:
```bash
redis-cli ping  # PONG dönmeli
```

## Lisans

MIT License
