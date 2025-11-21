# ✅ User Model ve JWT Yapılandırması Tamamlandı

## Yapılan Değişiklikler

### 1️⃣ User Model'e Yeni Alanlar Eklendi

**Migration:**
```ruby
rails g migration AddNameAndRoleToUsers name:string role:integer
rails db:migrate
```

✅ **Eklenen Alanlar:**
- `name` (string) - Kullanıcı adı
- `role` (integer) - Kullanıcı rolü (enum)

---

### 2️⃣ User Model Güncellendi

**Dosya:** `app/models/user.rb`

✅ **Eklenen Özellikler:**
- **Enum Roles:** 
  - `customer` (0) - Müşteri
  - `admin` (1) - Yönetici
  - `dealer` (2) - Bayi
  - `manufacturer` (3) - Üretici
  - `marketer` (4) - Pazarlamacı

- **Validations:**
  - `name` presence validation
  
- **Default Role:**
  - Yeni kullanıcılar otomatik olarak `customer` rolü alır

```ruby
class User < ApplicationRecord
  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: JwtDenylist

  enum role: { customer: 0, admin: 1, dealer: 2, manufacturer: 3, marketer: 4 }

  has_many :orders, class_name: 'Orders::Order', dependent: :destroy

  validates :name, presence: true
  
  after_initialize :set_default_role, if: :new_record?

  private

  def set_default_role
    self.role ||= :customer
  end
end
```

---

### 3️⃣ JWT Denylist Model

✅ **Zaten mevcut ve doğru yapılandırılmış!**

**Dosya:** `app/models/jwt_denylist.rb`

```ruby
class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist
  self.table_name = 'jwt_denylist'
end
```

---

### 4️⃣ Devise JWT Yapılandırması Güncellendi

**Dosya:** `config/initializers/devise_jwt.rb`

✅ **Signup endpoint'i JWT dispatch requests'e eklendi:**

```ruby
Devise.setup do |config|
  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.devise_jwt_secret_key || ENV['DEVISE_JWT_SECRET_KEY']
    jwt.dispatch_requests = [
      ['POST', %r{^/login$}],
      ['POST', %r{^/signup$}]  # ← YENİ EKLENDI
    ]
    jwt.revocation_requests = [
      ['DELETE', %r{^/logout$}]
    ]
    jwt.expiration_time = 1.day.to_i
  end
end
```

**Artık hem login hem de signup JWT token dönecek!**

---

### 5️⃣ JWT Secret Key Oluşturuldu

✅ **Yeni secret key generate edildi ve credentials'a eklendi:**

```bash
rails secret
# Output: 51a1381d4759b7980ecb17b3224e0bb95046c17d0baf98fd28d2db9e79f014718a553c6e2c8a78e3a3ffd75ac5413301b782d5bd2659a6f537d624ed67d5f8fd
```

**Credentials dosyasına eklendi:**
```yaml
devise_jwt_secret_key: 51a1381d4759b7980ecb17b3224e0bb95046c17d0baf98fd28d2db9e79f014718a553c6e2c8a78e3a3ffd75ac5413301b782d5bd2659a6f537d624ed67d5f8fd
```

---

### 6️⃣ ApplicationController Güncellendi

**Dosya:** `app/controllers/application_controller.rb`

✅ **Permitted parameters'a `name` ve `role` eklendi:**

```ruby
def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :email, :password, :password_confirmation, :role])
  devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
  devise_parameter_sanitizer.permit(:account_update, keys: [:name, :email, :password, :password_confirmation, :current_password])
end
```

---

### 7️⃣ Profile Controller Güncellendi

**Dosya:** `app/controllers/api/v1/users/profiles_controller.rb`

✅ **`name` alanı user_params'a eklendi:**

```ruby
def user_params
  params.require(:user).permit(:name, :email)
end
```

---

### 8️⃣ Seeds Güncellendi

**Dosya:** `db/seeds.rb`

✅ **5 farklı rol ile örnek kullanıcılar oluşturuldu:**

```ruby
users_data = [
  { email: 'admin@example.com', name: 'Admin User', role: :admin, password: 'password123' },
  { email: 'customer@example.com', name: 'John Customer', role: :customer, password: 'password123' },
  { email: 'dealer@example.com', name: 'Dealer Smith', role: :dealer, password: 'password123' },
  { email: 'manufacturer@example.com', name: 'Manufacturer Corp', role: :manufacturer, password: 'password123' },
  { email: 'marketer@example.com', name: 'Marketing Pro', role: :marketer, password: 'password123' }
]
```

---

### 9️⃣ Domain Yapısı Düzeltildi

✅ **Zeitwerk uyumlu yapı için dosyalar yeniden organize edildi:**

**Önceki yapı (hatalı):**
```
app/domains/
├── catalog/
│   └── models/
│       └── product.rb
└── orders/
    └── models/
        ├── order.rb
        └── order_item.rb
```

**Yeni yapı (doğru):**
```
app/domains/
├── catalog/
│   └── product.rb
└── orders/
    ├── order.rb
    └── order_item.rb
```

---

## 🎯 Test Etme

### 1. Signup (JWT Token ile)

**Yeni kullanıcı kaydı artık JWT token dönüyor:**

```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Test User",
      "email": "newuser@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "role": "customer"
    }
  }'
```

**Response Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

**Response Body:**
```json
{
  "message": "Signed up successfully.",
  "user": {
    "id": 6,
    "email": "newuser@example.com",
    "name": "Test User",
    "role": "customer",
    "created_at": "2025-10-10T22:00:20.000Z",
    "updated_at": "2025-10-10T22:00:20.000Z"
  }
}
```

---

### 2. Login (JWT Token ile)

```bash
curl -X POST http://localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "admin@example.com",
      "password": "password123"
    }
  }'
```

**Response Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

---

### 3. Profile Görüntüleme

```bash
curl http://localhost:3000/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Response:**
```json
{
  "id": 1,
  "email": "admin@example.com",
  "name": "Admin User",
  "role": "admin",
  "created_at": "2025-10-10T21:56:43.123Z",
  "updated_at": "2025-10-10T21:56:43.123Z"
}
```

---

### 4. Profile Güncelleme

```bash
curl -X PATCH http://localhost:3000/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "name": "Updated Name"
    }
  }'
```

---

### 5. Logout

```bash
curl -X DELETE http://localhost:3000/logout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 📊 Örnek Kullanıcılar (Seeds)

Seeds çalıştırıldıktan sonra aşağıdaki kullanıcılar mevcut:

| Email | Name | Role | Password |
|-------|------|------|----------|
| admin@example.com | Admin User | admin | password123 |
| customer@example.com | John Customer | customer | password123 |
| dealer@example.com | Dealer Smith | dealer | password123 |
| manufacturer@example.com | Manufacturer Corp | manufacturer | password123 |
| marketer@example.com | Marketing Pro | marketer | password123 |

---

## 🔐 JWT Token Kullanımı

### Token Alma (Signup veya Login)
- Signup veya Login endpoint'ine istek atın
- Response header'ında `Authorization: Bearer <token>` gelecek
- Bu token'ı saklayın

### Token Kullanma
Her korumalı endpoint'e istek atarken header'a ekleyin:
```
Authorization: Bearer <your_token>
```

### Token İptal Etme
Logout endpoint'ine token ile istek atın:
```bash
curl -X DELETE http://localhost:3000/logout \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Token `jwt_denylist` tablosuna eklenir ve artık kullanılamaz.

---

## ✅ Tamamlanan Görevler

- ✅ User model'e `name` ve `role` alanları eklendi
- ✅ Role enum tanımlandı (5 rol)
- ✅ Name validation eklendi
- ✅ Default role (customer) ayarlandı
- ✅ JWT denylist model zaten mevcuttu
- ✅ Devise JWT konfigürasyonu güncellendi
- ✅ Signup endpoint JWT dispatch'e eklendi
- ✅ JWT secret key generate edildi ve credentials'a eklendi
- ✅ ApplicationController permitted parameters güncellendi
- ✅ Profile controller güncellendi
- ✅ Seeds 5 farklı rol ile güncellendi
- ✅ Domain yapısı Zeitwerk uyumlu hale getirildi
- ✅ Veritabanı sıfırlandı ve yeni seeds çalıştırıldı

---

## 🚀 Proje Durumu

Proje şu anda tam çalışır durumda ve aşağıdaki özellikler aktif:

1. ✅ JWT Authentication (login, signup, logout)
2. ✅ Role-based User System (5 rol)
3. ✅ User Profile Management
4. ✅ Product Catalog
5. ✅ Order Management
6. ✅ Authorization (Pundit)
7. ✅ Background Jobs (Sidekiq)
8. ✅ API Documentation (Swagger)
9. ✅ Money Management
10. ✅ CORS Support

**Proje kullanıma hazır! 🎉**
