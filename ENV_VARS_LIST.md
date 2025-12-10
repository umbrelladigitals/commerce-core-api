# Production Environment Variables

Bu projeyi canlıya (production) alırken aşağıdaki ortam değişkenlerini (Environment Variables) sunucunuza veya platformunuza (Render, Heroku, Docker, vb.) eklemeniz gerekmektedir.

## Veritabanı (PostgreSQL)
*   `DATABASE_URL`: PostgreSQL bağlantı adresi.
    *   Örnek: `postgres://user:password@hostname:5432/dbname`

## Güvenlik
*   `RAILS_MASTER_KEY`: `config/master.key` dosyasının içeriği.
*   `SECRET_KEY_BASE`: (Opsiyonel) Eğer master key kullanılmıyorsa, Rails secret key. `rails secret` komutu ile üretilebilir.

## Frontend Entegrasyonu (CORS)
*   `FRONTEND_URL`: Frontend uygulamanızın çalıştığı adres. CORS ayarları için gereklidir.
    *   Örnek: `https://my-commerce-app.com`

## E-posta Bildirimleri (SMTP)
Bildirim sisteminin çalışması için gereklidir.
*   `SMTP_ADDRESS`: SMTP sunucu adresi (örn: `smtp.gmail.com` veya `smtp.sendgrid.net`).
*   `SMTP_PORT`: SMTP portu (genellikle `587`).
*   `SMTP_DOMAIN`: Gönderici domain (örn: `my-commerce-app.com`).
*   `SMTP_USERNAME`: SMTP kullanıcı adı.
*   `SMTP_PASSWORD`: SMTP şifresi.
*   `SMTP_AUTH`: Kimlik doğrulama tipi (genellikle `plain` veya `login`).
*   `SMTP_ENABLE_STARTTLS_AUTO`: `true` olmalıdır.

## Arkaplan İşlemleri & ActionCable (Redis)
*   `REDIS_URL`: Redis sunucu bağlantı adresi.
    *   Örnek: `redis://localhost:6379/1`

## Dosya Depolama (Cloudflare R2)
*   `R2_ACCESS_KEY_ID`: Cloudflare R2 Access Key ID.
*   `R2_SECRET_ACCESS_KEY`: Cloudflare R2 Secret Access Key.
*   `R2_BUCKET_NAME`: Bucket adı.
*   `R2_ENDPOINT`: S3 API Endpoint URL (örn: `https://<account_id>.r2.cloudflarestorage.com`).

## Ödeme Sistemi (Iyzico)
*   `IYZICO_API_KEY`: Iyzico API Anahtarı.
*   `IYZICO_SECRET_KEY`: Iyzico Gizli Anahtar.
*   `IYZICO_BASE_URL`: Iyzico API Adresi (Sandbox veya Production).
    *   Sandbox: `https://sandbox-api.iyzipay.com`
    *   Production: `https://api.iyzipay.com`

## Opsiyonel / Gelecek İçin
*   `RAILS_LOG_TO_STDOUT`: `true` (Logları standart çıktıya yönlendirir, konteyner yapılarında önerilir).
*   `RAILS_SERVE_STATIC_FILES`: `true` (Eğer Nginx/Apache arkasında değilse ve Rails statik dosyaları sunacaksa).
