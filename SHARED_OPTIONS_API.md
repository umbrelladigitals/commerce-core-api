# 🎨 Shared Options API

## Genel Bakış

Shared Options (Paylaşılan Seçenekler), ürün seçeneklerini tek bir yerden yönetmenizi ve ürünlere kolayca uygulamanızı sağlar.

## Modeller

### SharedOption
- `name`: Seçenek adı (örn: "Beden", "Renk")
- `option_type`: Tip (select, radio, checkbox, color)
- `required`: Zorunlu mu?
- `position`: Sıralama

### SharedOptionValue
- `name`: Değer adı (örn: "S", "M", "Kırmızı")
- `price_cents`: Ek ücret
- `price_mode`: Ücret tipi (flat, per_unit)

## API Endpoints

### 1. Shared Options Yönetimi (CRUD)

**Base URL:** `/api/v1/admin/shared_options`

#### Listeleme
`GET /api/v1/admin/shared_options`

#### Detay
`GET /api/v1/admin/shared_options/:id`

#### Oluşturma
`POST /api/v1/admin/shared_options`
```json
{
  "shared_option": {
    "name": "Hediye Paketi",
    "option_type": "checkbox",
    "required": false,
    "values_attributes": [
      { "name": "Standart Paket", "price_cents": 5000, "price_mode": "flat" },
      { "name": "Özel Paket", "price_cents": 10000, "price_mode": "flat" }
    ]
  }
}
```

#### Güncelleme
`PUT /api/v1/admin/shared_options/:id`

#### Silme
`DELETE /api/v1/admin/shared_options/:id`

### 2. Ürüne Uygulama

Bir Shared Option'ı bir ürüne kopyalar.

`POST /api/v1/admin/products/:product_id/product_options/import_shared`

**Body:**
```json
{
  "shared_option_id": 1
}
```

**Response:**
Oluşturulan `ProductOption` objesi döner.
