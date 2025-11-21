# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Eager load all domain models
Rails.application.eager_load!

# Create sample users with different roles
users_data = [
  { email: 'admin@example.com', name: 'Admin User', role: :admin, password: 'password123' },
  { email: 'customer@example.com', name: 'John Customer', role: :customer, password: 'password123' },
  { email: 'dealer@example.com', name: 'Dealer Smith', role: :dealer, password: 'password123' },
  { email: 'manufacturer@example.com', name: 'Manufacturer Corp', role: :manufacturer, password: 'password123' },
  { email: 'marketer@example.com', name: 'Marketing Pro', role: :marketer, password: 'password123' }
]

users = {}
users_data.each do |user_data|
  user = User.find_or_initialize_by(email: user_data[:email])
  if user.new_record?
    user.name = user_data[:name]
    user.role = user_data[:role]
    user.password = user_data[:password]
    user.password_confirmation = user_data[:password]
    user.save!
  end
  users[user_data[:role]] = user
  puts "Created #{user_data[:role]} user: #{user.email} (#{user.name})"
end

# Use customer for orders
user = users[:customer]

# Create categories - Turkish Restaurant Menu & Accessories
categories_data = [
  # Ana Kategoriler
  { name: 'Menü Kabı Modelleri', slug: 'menu-kabi-modelleri', parent_id: nil },
  { name: 'Menü Çeşitleri', slug: 'menu-cesitleri', parent_id: nil },
  { name: 'Masa Aksesuarları', slug: 'masa-aksesuarlari', parent_id: nil },
  { name: 'Servis Malzemeleri', slug: 'servis-malzemeleri', parent_id: nil },
  
  # Menü Kabı Alt Kategorileri
  { name: 'Deri Menü Kabı Modelleri', slug: 'deri-menu-kabi-modelleri', parent: 'Menü Kabı Modelleri' },
  { name: 'Ahşap Menü Kabı Modelleri', slug: 'ahsap-menu-kabi-modelleri', parent: 'Menü Kabı Modelleri' },
  { name: 'Diploma & Sertifika Kabı', slug: 'diploma-sertifika-kabi', parent: 'Menü Kabı Modelleri' },
  
  # Menü Çeşitleri Alt Kategorileri
  { name: 'Sıvama Menü', slug: 'sivama-menu', parent: 'Menü Çeşitleri' },
  { name: 'Tek Sayfa Menü', slug: 'tek-sayfa-menu', parent: 'Menü Çeşitleri' },
  { name: 'Hesap Sumanları', slug: 'hesap-sumenleri', parent: 'Menü Çeşitleri' },
  { name: 'QR Menü', slug: 'qr-menu', parent: 'Menü Çeşitleri' },
  
  # Masa Aksesuarları Alt Kategorileri
  { name: 'Amerikan Servisi', slug: 'amerikan-servisi', parent: 'Masa Aksesuarları' },
  { name: 'Çatal Kaşık Bıçak Kılıfı', slug: 'catal-kasik-bicak-kilifi', parent: 'Masa Aksesuarları' },
  { name: 'Masa Numaraları', slug: 'masa-numaralari', parent: 'Masa Aksesuarları' },
  { name: 'Peçetelikler', slug: 'pecetelikler', parent: 'Masa Aksesuarları' },
  { name: 'Masaüstü Rezerve', slug: 'masaustu-rezerve', parent: 'Masa Aksesuarları' },
  { name: 'Şupla', slug: 'supla', parent: 'Masa Aksesuarları' },
  { name: 'Runner', slug: 'runner', parent: 'Masa Aksesuarları' },
  
  # Servis Malzemeleri Alt Kategorileri
  { name: 'Çöp Kovaları', slug: 'cop-kovalari', parent: 'Servis Malzemeleri' },
  { name: 'Tepsiler', slug: 'tepsiler', parent: 'Servis Malzemeleri' }
]

categories = {}
categories_data.each do |cat_data|
  parent = cat_data[:parent] ? categories[cat_data[:parent]] : nil
  category = Catalog::Category.find_or_initialize_by(slug: cat_data[:slug])
  
  if category.new_record?
    category.name = cat_data[:name]
    category.parent = parent
    category.save!
  end
  
  categories[cat_data[:name]] = category
  puts "Created category: #{category.name} (#{category.slug})"
end

# Create products with categories - Turkish Restaurant Products
products_data = [
  # Deri Menü Kabı Modelleri
  { 
    title: 'Deri Menü Kabı - Kahverengi A4', 
    description: 'Premium kalite gerçek deri menü kabı, A4 boyutunda, kahverengi renk. Restoranlar için ideal.', 
    sku: 'DMK-KAH-A4',
    price_cents: 45000, 
    currency: 'TRY',
    active: true,
    category: 'Deri Menü Kabı Modelleri'
  },
  { 
    title: 'Deri Menü Kabı - Siyah A4', 
    description: 'Şık siyah deri menü kabı, dayanıklı ve zarif tasarım.', 
    sku: 'DMK-SIY-A4',
    price_cents: 45000, 
    currency: 'TRY',
    active: true,
    category: 'Deri Menü Kabı Modelleri'
  },
  { 
    title: 'Deri Menü Kabı - Bordo A4', 
    description: 'Bordo renk deri menü kabı, premium restoran deneyimi için.', 
    sku: 'DMK-BOR-A4',
    price_cents: 48000, 
    currency: 'TRY',
    active: true,
    category: 'Deri Menü Kabı Modelleri'
  },
  
  # Ahşap Menü Kabı Modelleri
  { 
    title: 'Ahşap Menü Kabı - Ceviz', 
    description: 'Doğal ceviz ağacından üretilmiş menü kabı, rustik tasarım.', 
    sku: 'AMK-CEV-A4',
    price_cents: 38000, 
    currency: 'TRY',
    active: true,
    category: 'Ahşap Menü Kabı Modelleri'
  },
  { 
    title: 'Ahşap Menü Kabı - Bambu', 
    description: 'Çevre dostu bambu menü kabı, modern ve şık.', 
    sku: 'AMK-BAM-A4',
    price_cents: 35000, 
    currency: 'TRY',
    active: true,
    category: 'Ahşap Menü Kabı Modelleri'
  },
  { 
    title: 'Ahşap Menü Kabı - Meşe', 
    description: 'Sağlam meşe ağacı menü kabı, uzun ömürlü.', 
    sku: 'AMK-MES-A4',
    price_cents: 42000, 
    currency: 'TRY',
    active: true,
    category: 'Ahşap Menü Kabı Modelleri'
  },
  
  # Sıvama Menü
  { 
    title: 'Sıvama Menü - A4 Mat Lamine', 
    description: '4 sayfa A4 boyutunda mat lamine sıvama menü.', 
    sku: 'SVM-A4-MAT',
    price_cents: 12000, 
    currency: 'TRY',
    active: true,
    category: 'Sıvama Menü'
  },
  { 
    title: 'Sıvama Menü - A4 Parlak Lamine', 
    description: '4 sayfa A4 boyutunda parlak lamine sıvama menü.', 
    sku: 'SVM-A4-PAR',
    price_cents: 12000, 
    currency: 'TRY',
    active: true,
    category: 'Sıvama Menü'
  },
  { 
    title: 'Sıvama Menü - A3 Mat Lamine', 
    description: '2 sayfa A3 boyutunda mat lamine sıvama menü.', 
    sku: 'SVM-A3-MAT',
    price_cents: 15000, 
    currency: 'TRY',
    active: true,
    category: 'Sıvama Menü'
  },
  
  # Tek Sayfa Menü
  { 
    title: 'Tek Sayfa Menü - A4 Kuşe', 
    description: 'Tek sayfa A4 boyutunda 300gr kuşe kağıt menü.', 
    sku: 'TSM-A4-300',
    price_cents: 3500, 
    currency: 'TRY',
    active: true,
    category: 'Tek Sayfa Menü'
  },
  { 
    title: 'Tek Sayfa Menü - A3 Kuşe', 
    description: 'Tek sayfa A3 boyutunda 300gr kuşe kağıt menü.', 
    sku: 'TSM-A3-300',
    price_cents: 5000, 
    currency: 'TRY',
    active: true,
    category: 'Tek Sayfa Menü'
  },
  
  # Amerikan Servisi
  { 
    title: 'Amerikan Servisi - Deri Kahverengi', 
    description: 'Deri amerikan servisi takımı, 4 adet set.', 
    sku: 'AMS-DER-KAH',
    price_cents: 28000, 
    currency: 'TRY',
    active: true,
    category: 'Amerikan Servisi'
  },
  { 
    title: 'Amerikan Servisi - Bambu', 
    description: 'Bambu amerikan servisi, çevre dostu.', 
    sku: 'AMS-BAM-SET',
    price_cents: 22000, 
    currency: 'TRY',
    active: true,
    category: 'Amerikan Servisi'
  },
  { 
    title: 'Amerikan Servisi - Premium Deri Siyah', 
    description: 'Premium siyah deri amerikan servisi, lüks görünüm.', 
    sku: 'AMS-DER-SIY',
    price_cents: 32000, 
    currency: 'TRY',
    active: true,
    category: 'Amerikan Servisi'
  },
  
  # Masa Numaraları
  { 
    title: 'Masa Numaraları - Ahşap 1-20', 
    description: 'Ahşap masa numaraları seti, 1-20 arası.', 
    sku: 'MNO-AHS-20',
    price_cents: 15000, 
    currency: 'TRY',
    active: true,
    category: 'Masa Numaraları'
  },
  { 
    title: 'Masa Numaraları - Metal Gold 1-30', 
    description: 'Metal gold kaplama masa numaraları, 1-30 arası.', 
    sku: 'MNO-MET-30',
    price_cents: 25000, 
    currency: 'TRY',
    active: true,
    category: 'Masa Numaraları'
  },
  { 
    title: 'Masa Numaraları - Akrilik Şeffaf 1-15', 
    description: 'Modern akrilik şeffaf masa numaraları, 1-15 arası.', 
    sku: 'MNO-AKR-15',
    price_cents: 12000, 
    currency: 'TRY',
    active: true,
    category: 'Masa Numaraları'
  },
  
  # Peçetelikler
  { 
    title: 'Peçetelik - Deri Kahverengi', 
    description: 'Deri peçetelik, şık ve dayanıklı.', 
    sku: 'PCL-DER-KAH',
    price_cents: 8500, 
    currency: 'TRY',
    active: true,
    category: 'Peçetelikler'
  },
  { 
    title: 'Peçetelik - Metal Siyah', 
    description: 'Metal peçetelik, modern tasarım.', 
    sku: 'PCL-MET-SIY',
    price_cents: 7500, 
    currency: 'TRY',
    active: true,
    category: 'Peçetelikler'
  },
  { 
    title: 'Peçetelik - Ahşap Ceviz', 
    description: 'Ceviz ağacı peçetelik, doğal görünüm.', 
    sku: 'PCL-AHS-CEV',
    price_cents: 9000, 
    currency: 'TRY',
    active: true,
    category: 'Peçetelikler'
  },
  
  # QR Menü
  { 
    title: 'QR Menü Standı - Akrilik', 
    description: 'Akrilik QR menü standı, masa üstü kullanım.', 
    sku: 'QRM-AKR-STD',
    price_cents: 4500, 
    currency: 'TRY',
    active: true,
    category: 'QR Menü'
  },
  { 
    title: 'QR Menü Çerçevesi - Ahşap', 
    description: 'Ahşap QR menü çerçevesi, şık tasarım.', 
    sku: 'QRM-AHS-CER',
    price_cents: 6000, 
    currency: 'TRY',
    active: true,
    category: 'QR Menü'
  },
  
  # Hesap Sumanları
  { 
    title: 'Hesap Sumanı - Deri Siyah', 
    description: 'Deri hesap sumanı, profesyonel görünüm.', 
    sku: 'HSM-DER-SIY',
    price_cents: 8000, 
    currency: 'TRY',
    active: true,
    category: 'Hesap Sumanları'
  },
  { 
    title: 'Hesap Sumanı - Deri Kahverengi', 
    description: 'Kahverengi deri hesap sumanı, klasik.', 
    sku: 'HSM-DER-KAH',
    price_cents: 8000, 
    currency: 'TRY',
    active: true,
    category: 'Hesap Sumanları'
  },
  
  # Diploma & Sertifika Kabı
  { 
    title: 'Diploma Kabı - Deri Bordo', 
    description: 'Premium deri diploma ve sertifika kabı, bordo renk.', 
    sku: 'DPK-DER-BOR',
    price_cents: 35000, 
    currency: 'TRY',
    active: true,
    category: 'Diploma & Sertifika Kabı'
  },
  { 
    title: 'Sertifika Kabı - Deri Siyah', 
    description: 'Şık siyah deri sertifika kabı, A4 boyutunda.', 
    sku: 'SRK-DER-SIY',
    price_cents: 32000, 
    currency: 'TRY',
    active: true,
    category: 'Diploma & Sertifika Kabı'
  },
  
  # Çatal Kaşık Bıçak Kılıfı
  { 
    title: 'Çatal Bıçak Kılıfı - Lüks Kumaş', 
    description: 'Lüks kumaş çatal kaşık bıçak kılıfı, 50 adet.', 
    sku: 'CBK-KUM-LUX',
    price_cents: 15000, 
    currency: 'TRY',
    active: true,
    category: 'Çatal Kaşık Bıçak Kılıfı'
  },
  { 
    title: 'Çatal Bıçak Kılıfı - Kağıt Desenli', 
    description: 'Desenli kağıt çatal kaşık bıçak kılıfı, 100 adet.', 
    sku: 'CBK-KAG-DES',
    price_cents: 8000, 
    currency: 'TRY',
    active: true,
    category: 'Çatal Kaşık Bıçak Kılıfı'
  },
  
  # Masaüstü Rezerve
  { 
    title: 'Rezerve Levhası - Akrilik Gold', 
    description: 'Gold renkli akrilik rezerve levhası, 10 adet set.', 
    sku: 'RZV-AKR-GLD',
    price_cents: 12000, 
    currency: 'TRY',
    active: true,
    category: 'Masaüstü Rezerve'
  },
  { 
    title: 'Rezerve Levhası - Ahşap', 
    description: 'Ahşap rezerve levhası, 10 adet set.', 
    sku: 'RZV-AHS-SET',
    price_cents: 10000, 
    currency: 'TRY',
    active: true,
    category: 'Masaüstü Rezerve'
  },
  
  # Şupla
  { 
    title: 'Şupla - Hasır Doğal', 
    description: 'Doğal hasır şupla, 6 adet set.', 
    sku: 'SUP-HAS-DOG',
    price_cents: 18000, 
    currency: 'TRY',
    active: true,
    category: 'Şupla'
  },
  { 
    title: 'Şupla - PVC Modern Desenli', 
    description: 'Modern desenli PVC şupla, 6 adet set.', 
    sku: 'SUP-PVC-MOD',
    price_cents: 12000, 
    currency: 'TRY',
    active: true,
    category: 'Şupla'
  },
  
  # Runner
  { 
    title: 'Runner - Keten Doğal', 
    description: 'Doğal keten runner, 150x40 cm.', 
    sku: 'RUN-KET-DOG',
    price_cents: 15000, 
    currency: 'TRY',
    active: true,
    category: 'Runner'
  },
  { 
    title: 'Runner - Jakarlı Lüks', 
    description: 'Lüks jakarlı runner, desenli, 150x40 cm.', 
    sku: 'RUN-JAK-LUX',
    price_cents: 22000, 
    currency: 'TRY',
    active: true,
    category: 'Runner'
  },
  
  # Çöp Kovaları
  { 
    title: 'Çöp Kovası - Paslanmaz Çelik 40L', 
    description: 'Pedallı paslanmaz çelik çöp kovası, 40 litre.', 
    sku: 'CPK-PAS-40L',
    price_cents: 85000, 
    currency: 'TRY',
    active: true,
    category: 'Çöp Kovaları'
  },
  { 
    title: 'Çöp Kovası - Plastik 25L', 
    description: 'Pratik plastik çöp kovası, 25 litre.', 
    sku: 'CPK-PLS-25L',
    price_cents: 35000, 
    currency: 'TRY',
    active: true,
    category: 'Çöp Kovaları'
  },
  
  # Tepsiler
  { 
    title: 'Servis Tepsisi - Dikdörtgen Ahşap', 
    description: 'Ahşap servis tepsisi, 40x30 cm.', 
    sku: 'TPS-AHS-40X30',
    price_cents: 28000, 
    currency: 'TRY',
    active: true,
    category: 'Tepsiler'
  },
  { 
    title: 'Servis Tepsisi - Yuvarlak Metal', 
    description: 'Metal servis tepsisi, 35 cm çap.', 
    sku: 'TPS-MET-35CM',
    price_cents: 25000, 
    currency: 'TRY',
    active: true,
    category: 'Tepsiler'
  },
  { 
    title: 'Servis Tepsisi - Kaymaz Tabanlı', 
    description: 'Kaymaz tabanlı servis tepsisi, 45x35 cm.', 
    sku: 'TPS-KAY-45X35',
    price_cents: 32000, 
    currency: 'TRY',
    active: true,
    category: 'Tepsiler'
  }
]

products = {}
products_data.each do |product_data|
  category = categories[product_data[:category]]
  product = Catalog::Product.find_or_initialize_by(sku: product_data[:sku])
  
  if product.new_record?
    product.title = product_data[:title]
    product.description = product_data[:description]
    product.price_cents = product_data[:price_cents]
    product.currency = product_data[:currency]
    product.active = product_data[:active]
    product.category = category
    product.save!
  end
  
  products[product_data[:title]] = product
  puts "Created product: #{product.title} (#{product.sku}) - $#{product.price_cents / 100.0}"
end

# Create variants for products - Turkish Restaurant Products
variants_data = [
  # Deri Menü Kabı Varyantları
  { 
    product: 'Deri Menü Kabı - Kahverengi A4', 
    sku: 'DMK-KAH-A4-2SF',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Yok' },
    price_cents: 45000,
    stock: 50
  },
  { 
    product: 'Deri Menü Kabı - Kahverengi A4', 
    sku: 'DMK-KAH-A4-4SF',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', logo_baski: 'Yok' },
    price_cents: 48000,
    stock: 45
  },
  { 
    product: 'Deri Menü Kabı - Kahverengi A4', 
    sku: 'DMK-KAH-A4-2SF-LOGO',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Var' },
    price_cents: 50000,
    stock: 30
  },
  
  { 
    product: 'Deri Menü Kabı - Siyah A4', 
    sku: 'DMK-SIY-A4-2SF',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Yok' },
    price_cents: 45000,
    stock: 40
  },
  { 
    product: 'Deri Menü Kabı - Siyah A4', 
    sku: 'DMK-SIY-A4-4SF',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', logo_baski: 'Yok' },
    price_cents: 48000,
    stock: 35
  },
  { 
    product: 'Deri Menü Kabı - Siyah A4', 
    sku: 'DMK-SIY-A4-2SF-LOGO',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Var' },
    price_cents: 50000,
    stock: 25
  },
  
  { 
    product: 'Deri Menü Kabı - Bordo A4', 
    sku: 'DMK-BOR-A4-2SF',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Yok' },
    price_cents: 48000,
    stock: 30
  },
  { 
    product: 'Deri Menü Kabı - Bordo A4', 
    sku: 'DMK-BOR-A4-4SF-LOGO',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', logo_baski: 'Var' },
    price_cents: 55000,
    stock: 20
  },
  
  # Ahşap Menü Kabı Varyantları
  { 
    product: 'Ahşap Menü Kabı - Ceviz', 
    sku: 'AMK-CEV-A4-2SF',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Yok' },
    price_cents: 38000,
    stock: 60
  },
  { 
    product: 'Ahşap Menü Kabı - Ceviz', 
    sku: 'AMK-CEV-A4-4SF',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', logo_baski: 'Yok' },
    price_cents: 42000,
    stock: 50
  },
  { 
    product: 'Ahşap Menü Kabı - Ceviz', 
    sku: 'AMK-CEV-A4-2SF-LOGO',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Var' },
    price_cents: 43000,
    stock: 35
  },
  
  { 
    product: 'Ahşap Menü Kabı - Bambu', 
    sku: 'AMK-BAM-A4-2SF',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Yok' },
    price_cents: 35000,
    stock: 70
  },
  { 
    product: 'Ahşap Menü Kabı - Bambu', 
    sku: 'AMK-BAM-A4-4SF-LOGO',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', logo_baski: 'Var' },
    price_cents: 42000,
    stock: 40
  },
  
  { 
    product: 'Ahşap Menü Kabı - Meşe', 
    sku: 'AMK-MES-A4-2SF',
    options: { boyut: 'A4', ic_sayfa: '2 Sayfa', logo_baski: 'Yok' },
    price_cents: 42000,
    stock: 45
  },
  { 
    product: 'Ahşap Menü Kabı - Meşe', 
    sku: 'AMK-MES-A4-4SF',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', logo_baski: 'Yok' },
    price_cents: 46000,
    stock: 38
  },
  
  # Sıvama Menü Varyantları
  { 
    product: 'Sıvama Menü - A4 Mat Lamine', 
    sku: 'SVM-A4-MAT-4SF',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', laminasyon: 'Mat' },
    price_cents: 12000,
    stock: 200
  },
  { 
    product: 'Sıvama Menü - A4 Mat Lamine', 
    sku: 'SVM-A4-MAT-6SF',
    options: { boyut: 'A4', ic_sayfa: '6 Sayfa', laminasyon: 'Mat' },
    price_cents: 15000,
    stock: 150
  },
  
  { 
    product: 'Sıvama Menü - A4 Parlak Lamine', 
    sku: 'SVM-A4-PAR-4SF',
    options: { boyut: 'A4', ic_sayfa: '4 Sayfa', laminasyon: 'Parlak' },
    price_cents: 12000,
    stock: 180
  },
  { 
    product: 'Sıvama Menü - A4 Parlak Lamine', 
    sku: 'SVM-A4-PAR-6SF',
    options: { boyut: 'A4', ic_sayfa: '6 Sayfa', laminasyon: 'Parlak' },
    price_cents: 15000,
    stock: 140
  },
  
  { 
    product: 'Sıvama Menü - A3 Mat Lamine', 
    sku: 'SVM-A3-MAT-2SF',
    options: { boyut: 'A3', ic_sayfa: '2 Sayfa', laminasyon: 'Mat' },
    price_cents: 15000,
    stock: 120
  },
  { 
    product: 'Sıvama Menü - A3 Mat Lamine', 
    sku: 'SVM-A3-MAT-4SF',
    options: { boyut: 'A3', ic_sayfa: '4 Sayfa', laminasyon: 'Mat' },
    price_cents: 18000,
    stock: 100
  },
  
  # Amerikan Servisi Varyantları
  { 
    product: 'Amerikan Servisi - Deri Kahverengi', 
    sku: 'AMS-DER-KAH-4LU',
    options: { adet: '4 Adet', renk: 'Kahverengi', malzeme: 'Deri' },
    price_cents: 28000,
    stock: 50
  },
  { 
    product: 'Amerikan Servisi - Deri Kahverengi', 
    sku: 'AMS-DER-KAH-6LU',
    options: { adet: '6 Adet', renk: 'Kahverengi', malzeme: 'Deri' },
    price_cents: 40000,
    stock: 35
  },
  
  { 
    product: 'Amerikan Servisi - Bambu', 
    sku: 'AMS-BAM-SET-4LU',
    options: { adet: '4 Adet', renk: 'Doğal', malzeme: 'Bambu' },
    price_cents: 22000,
    stock: 80
  },
  { 
    product: 'Amerikan Servisi - Bambu', 
    sku: 'AMS-BAM-SET-6LU',
    options: { adet: '6 Adet', renk: 'Doğal', malzeme: 'Bambu' },
    price_cents: 32000,
    stock: 60
  },
  
  { 
    product: 'Amerikan Servisi - Premium Deri Siyah', 
    sku: 'AMS-DER-SIY-4LU',
    options: { adet: '4 Adet', renk: 'Siyah', malzeme: 'Premium Deri' },
    price_cents: 32000,
    stock: 40
  },
  { 
    product: 'Amerikan Servisi - Premium Deri Siyah', 
    sku: 'AMS-DER-SIY-6LU',
    options: { adet: '6 Adet', renk: 'Siyah', malzeme: 'Premium Deri' },
    price_cents: 46000,
    stock: 30
  },
  
  # Şupla Varyantları
  { 
    product: 'Şupla - Hasır Doğal', 
    sku: 'SUP-HAS-DOG-6LU',
    options: { adet: '6 Adet', malzeme: 'Hasır', renk: 'Doğal' },
    price_cents: 18000,
    stock: 100
  },
  { 
    product: 'Şupla - Hasır Doğal', 
    sku: 'SUP-HAS-DOG-12LU',
    options: { adet: '12 Adet', malzeme: 'Hasır', renk: 'Doğal' },
    price_cents: 34000,
    stock: 70
  },
  
  { 
    product: 'Şupla - PVC Modern Desenli', 
    sku: 'SUP-PVC-MOD-6LU',
    options: { adet: '6 Adet', malzeme: 'PVC', desen: 'Modern' },
    price_cents: 12000,
    stock: 150
  },
  { 
    product: 'Şupla - PVC Modern Desenli', 
    sku: 'SUP-PVC-MOD-12LU',
    options: { adet: '12 Adet', malzeme: 'PVC', desen: 'Modern' },
    price_cents: 22000,
    stock: 120
  }
]

variants_data.each do |variant_data|
  product = products[variant_data[:product]]
  next unless product
  
  variant = Catalog::Variant.find_or_initialize_by(sku: variant_data[:sku])
  
  if variant.new_record?
    variant.product = product
    variant.options = variant_data[:options]
    variant.price_cents = variant_data[:price_cents]
    variant.stock = variant_data[:stock]
    variant.currency = 'TRY'
    variant.save!
  end
  
  puts "Created variant: #{variant.display_name} (#{variant.sku}) - Stock: #{variant.stock}"
end

# Create sample orders
puts "\n📦 Creating sample orders..."

# Order 1: Active cart (sepet)
cart = Orders::Order.find_or_create_by!(user: users[:customer], status: :cart) do |o|
  o.currency = 'USD'
  o.total_cents = 0
  o.subtotal_cents = 0
  o.tax_cents = 0
  o.shipping_cents = 0
end

laptop_variant = Catalog::Variant.find_by(sku: 'MBP-16-M2-512GB-SILVER')
mouse_product = Catalog::Product.find_by(sku: 'LGT-MX3')

if laptop_variant && mouse_product && cart.order_lines.empty?
  # Add laptop variant
  cart.order_lines.create!(
    product: laptop_variant.product,
    variant: laptop_variant,
    quantity: 1,
    unit_price_cents: laptop_variant.price_cents,
    total_cents: laptop_variant.price_cents
  )
  
  # Add mouse (no variant)
  cart.order_lines.create!(
    product: mouse_product,
    variant: nil,
    quantity: 2,
    unit_price_cents: mouse_product.price_cents,
    total_cents: mouse_product.price_cents * 2
  )
  
  # Calculate totals
  Orders::OrderPriceCalculator.new(cart).calculate!
  puts "Created cart order ##{cart.id} (#{cart.order_number}) - Status: #{cart.status} - Total: #{cart.total.format}"
end

# Order 2: Paid order (ödeme alınmış)
paid_order = Orders::Order.find_or_create_by!(user: users[:dealer], status: :paid) do |o|
  o.currency = 'USD'
  o.total_cents = 0
  o.subtotal_cents = 0
  o.tax_cents = 0
  o.shipping_cents = 0
  o.paid_at = 2.days.ago
end

keyboard_variant = Catalog::Variant.find_by(sku: 'KEY-K2-RED')
headphone_product = Catalog::Product.find_by(sku: 'SONY-WH1000XM5')

if keyboard_variant && headphone_product && paid_order.order_lines.empty?
  paid_order.order_lines.create!(
    product: keyboard_variant.product,
    variant: keyboard_variant,
    quantity: 3,
    unit_price_cents: keyboard_variant.price_cents,
    total_cents: keyboard_variant.price_cents * 3
  )
  
  paid_order.order_lines.create!(
    product: headphone_product,
    variant: nil,
    quantity: 1,
    unit_price_cents: headphone_product.price_cents,
    total_cents: headphone_product.price_cents
  )
  
  Orders::OrderPriceCalculator.new(paid_order).calculate!
  puts "Created paid order ##{paid_order.id} (#{paid_order.order_number}) - Status: #{paid_order.status} - Total: #{paid_order.total.format}"
end

# Create B2B data (Dealer discounts and balances)
puts "\n💼 Creating B2B data..."

dealer_user = users[:dealer]

# Dealer bakiyesi otomatik oluşturuldu (callback ile), güncelle
if dealer_user.dealer_balance
  dealer_user.dealer_balance.update!(
    balance_cents: 50000,      # 500.00 TL pozitif bakiye
    credit_limit_cents: 100000 # 1000.00 TL kredi limiti
  )
  puts "Updated dealer balance: #{dealer_user.dealer_balance.balance.format} (Credit Limit: #{dealer_user.dealer_balance.credit_limit.format})"
end

# Dealer indirimleri oluştur
discounts_data = [
  { product_sku: 'MBP-16-M2', discount_percent: 10.0 },     # MacBook Pro %10
  { product_sku: 'DELL-XPS-15', discount_percent: 12.5 },   # Dell XPS %12.5
  { product_sku: 'LGT-MX3', discount_percent: 20.0 },       # Mouse %20
  { product_sku: 'KEY-K2', discount_percent: 15.0 }         # Keyboard %15
]

discounts_data.each do |data|
  product = Catalog::Product.find_by(sku: data[:product_sku])
  next unless product
  
  discount = B2b::DealerDiscount.find_or_create_by!(
    dealer: dealer_user,
    product: product
  ) do |d|
    d.discount_percent = data[:discount_percent]
    d.active = true
  end
  
  puts "Created dealer discount: #{product.title} - #{discount.formatted_discount}"
end

# Product Options (ürün opsiyonları) oluştur
puts "\n📦 Creating product options..."

# MacBook Pro için opsiyonlar
macbook = products['MacBook Pro 16"']
if macbook
  # Warranty option
  warranty_option = Catalog::ProductOption.find_or_create_by!(
    product: macbook,
    name: 'Warranty'
  ) do |opt|
    opt.option_type = 'select'
    opt.required = false
    opt.position = 0
  end

  warranty_values = [
    { name: 'No Extended Warranty', price_cents: 0, price_mode: 'flat', position: 0 },
    { name: '1 Year Extended Warranty', price_cents: 19900, price_mode: 'flat', position: 1 },
    { name: '2 Year Extended Warranty', price_cents: 29900, price_mode: 'flat', position: 2 },
    { name: '3 Year AppleCare+', price_cents: 39900, price_mode: 'flat', position: 3 }
  ]

  warranty_values.each do |val_data|
    Catalog::ProductOptionValue.find_or_create_by!(
      product_option: warranty_option,
      name: val_data[:name]
    ) do |val|
      val.price_cents = val_data[:price_cents]
      val.price_mode = val_data[:price_mode]
      val.position = val_data[:position]
    end
  end

  # Engraving option (per unit - her karaktere fiyat)
  engraving_option = Catalog::ProductOption.find_or_create_by!(
    product: macbook,
    name: 'Engraving'
  ) do |opt|
    opt.option_type = 'checkbox'
    opt.required = false
    opt.position = 1
  end

  Catalog::ProductOptionValue.find_or_create_by!(
    product_option: engraving_option,
    name: 'Add Custom Engraving'
  ) do |val|
    val.price_cents = 4900
    val.price_mode = 'flat'
    val.position = 0
    val.meta = { max_characters: 25, description: 'Personalize your MacBook with custom engraving' }
  end

  puts "  ✓ Created options for #{macbook.title}"
end

# Sony Headphones için opsiyonlar
sony = products['Sony WH-1000XM5']
if sony
  # Gift wrapping
  gift_option = Catalog::ProductOption.find_or_create_by!(
    product: sony,
    name: 'Gift Wrapping'
  ) do |opt|
    opt.option_type = 'radio'
    opt.required = false
    opt.position = 0
  end

  gift_values = [
    { name: 'No Gift Wrap', price_cents: 0, price_mode: 'flat' },
    { name: 'Standard Gift Wrap', price_cents: 500, price_mode: 'flat' },
    { name: 'Premium Gift Wrap', price_cents: 1500, price_mode: 'flat' }
  ]

  gift_values.each_with_index do |val_data, idx|
    Catalog::ProductOptionValue.find_or_create_by!(
      product_option: gift_option,
      name: val_data[:name]
    ) do |val|
      val.price_cents = val_data[:price_cents]
      val.price_mode = val_data[:price_mode]
      val.position = idx
    end
  end

  # Carrying case
  case_option = Catalog::ProductOption.find_or_create_by!(
    product: sony,
    name: 'Carrying Case'
  ) do |opt|
    opt.option_type = 'select'
    opt.required = false
    opt.position = 1
  end

  case_values = [
    { name: 'No Case', price_cents: 0, price_mode: 'flat', meta: {} },
    { name: 'Basic Soft Case', price_cents: 1900, price_mode: 'flat', meta: { color: 'Black' } },
    { name: 'Premium Hard Case', price_cents: 3900, price_mode: 'flat', meta: { color: 'Black', water_resistant: true } }
  ]

  case_values.each_with_index do |val_data, idx|
    Catalog::ProductOptionValue.find_or_create_by!(
      product_option: case_option,
      name: val_data[:name]
    ) do |val|
      val.price_cents = val_data[:price_cents]
      val.price_mode = val_data[:price_mode]
      val.position = idx
      val.meta = val_data[:meta]
    end
  end

  puts "  ✓ Created options for #{sony.title}"
end

# Keychron Keyboard için opsiyonlar
keychron = products['Keychron K2']
if keychron
  # Keycaps
  keycaps_option = Catalog::ProductOption.find_or_create_by!(
    product: keychron,
    name: 'Extra Keycaps'
  ) do |opt|
    opt.option_type = 'checkbox'
    opt.required = false
    opt.position = 0
  end

  Catalog::ProductOptionValue.find_or_create_by!(
    product_option: keycaps_option,
    name: 'Add Extra Keycap Set'
  ) do |val|
    val.price_cents = 2500
    val.price_mode = 'flat'
    val.position = 0
    val.meta = { colors: ['White', 'Black', 'Red'], material: 'PBT' }
  end

  # USB Cable
  cable_option = Catalog::ProductOption.find_or_create_by!(
    product: keychron,
    name: 'USB Cable Upgrade'
  ) do |opt|
    opt.option_type = 'select'
    opt.required = false
    opt.position = 1
  end

  cable_values = [
    { name: 'Standard Cable (included)', price_cents: 0, price_mode: 'flat' },
    { name: 'Coiled Cable - Black', price_cents: 1500, price_mode: 'flat' },
    { name: 'Coiled Cable - White', price_cents: 1500, price_mode: 'flat' },
    { name: 'Braided Cable - Red', price_cents: 2000, price_mode: 'flat' }
  ]

  cable_values.each_with_index do |val_data, idx|
    Catalog::ProductOptionValue.find_or_create_by!(
      product_option: cable_option,
      name: val_data[:name]
    ) do |val|
      val.price_cents = val_data[:price_cents]
      val.price_mode = val_data[:price_mode]
      val.position = idx
    end
  end

  puts "  ✓ Created options for #{keychron.title}"
end

# Mouse için opsiyonlar (per_unit örneği)
mouse = products['Logitech MX Master 3']
if mouse
  # Extra batteries (per unit - her pil için)
  battery_option = Catalog::ProductOption.find_or_create_by!(
    product: mouse,
    name: 'Extra Batteries'
  ) do |opt|
    opt.option_type = 'select'
    opt.required = false
    opt.position = 0
  end

  battery_values = [
    { name: 'No Extra Batteries', price_cents: 0, price_mode: 'flat', quantity: 0 },
    { name: '2 Extra Batteries', price_cents: 500, price_mode: 'per_unit', quantity: 2 },
    { name: '4 Extra Batteries', price_cents: 500, price_mode: 'per_unit', quantity: 4 }
  ]

  battery_values.each_with_index do |val_data, idx|
    Catalog::ProductOptionValue.find_or_create_by!(
      product_option: battery_option,
      name: val_data[:name]
    ) do |val|
      val.price_cents = val_data[:price_cents]
      val.price_mode = val_data[:price_mode]
      val.position = idx
      val.meta = { quantity: val_data[:quantity] }
    end
  end

  puts "  ✓ Created options for #{mouse.title}"
end

# Create notification templates
puts "\n📧 Creating notification templates..."

notification_templates = [
  {
    name: 'order_status_paid',
    channel: 'email',
    subject: 'Order Confirmation - Order #{{order_number}}',
    body: <<~BODY
      Dear {{customer_name}},

      Thank you for your order! We have received your payment.

      Order Details:
      - Order Number: {{order_number}}
      - Order Date: {{order_date}}
      - Total Amount: {{total}}

      We will notify you once your order is shipped.

      Best regards,
      The Commerce Team
    BODY
  },
  {
    name: 'order_status_shipped',
    channel: 'email',
    subject: 'Your Order Has Been Shipped - Order #{{order_number}}',
    body: <<~BODY
      Dear {{customer_name}},

      Great news! Your order has been shipped.

      Order Details:
      - Order Number: {{order_number}}
      - Tracking Number: {{tracking}}
      - Shipping Date: {{order_date}}

      You can track your package using the tracking number above.

      Best regards,
      The Commerce Team
    BODY
  },
  {
    name: 'order_status_cancelled',
    channel: 'email',
    subject: 'Order Cancelled - Order #{{order_number}}',
    body: <<~BODY
      Dear {{customer_name}},

      Your order has been cancelled as requested.

      Order Details:
      - Order Number: {{order_number}}
      - Total Amount: {{total}}

      If this was a mistake, please contact our support team.

      Best regards,
      The Commerce Team
    BODY
  },
  {
    name: 'welcome_message',
    channel: 'sms',
    subject: nil,
    body: 'Welcome {{customer_name}}! Thank you for joining us. Your account is ready.'
  },
  {
    name: 'order_shipped_sms',
    channel: 'sms',
    subject: nil,
    body: 'Your order {{order_number}} has been shipped! Track: {{tracking}}'
  },
  {
    name: 'order_shipped_whatsapp',
    channel: 'whatsapp',
    subject: nil,
    body: 'Hello {{customer_name}}! 📦 Your order {{order_number}} is on its way. Tracking: {{tracking}}'
  }
]

notification_templates.each do |template_data|
  template = NotificationTemplate.find_or_initialize_by(
    name: template_data[:name],
    channel: template_data[:channel]
  )
  
  if template.new_record?
    template.assign_attributes(template_data)
    template.save!
    puts "  ✓ Created template: #{template.name} (#{template.channel})"
  else
    puts "  - Template already exists: #{template.name}"
  end
end

puts "\n✅ Seed data created successfully!"
puts "\n📊 Summary:"
puts "  - #{Catalog::Category.count} categories"
puts "  - #{Catalog::Product.count} products"
puts "  - #{Catalog::Variant.count} variants"
puts "  - #{Catalog::ProductOption.count} product options"
puts "  - #{Catalog::ProductOptionValue.count} product option values"
puts "  - #{User.count} users"
puts "  - #{Orders::Order.count} orders"
puts "  - #{B2b::DealerDiscount.count} dealer discounts"
puts "  - #{B2b::DealerBalance.count} dealer balances"
puts "  - #{NotificationTemplate.count} notification templates"

# Create Sliders
puts "\nCreating sliders..."
sliders_data = [
  {
    title: 'Premium Restoran Ürünleri',
    subtitle: 'Restoranınız için özel tasarlanmış menü kapları, amerikan servisleri ve daha fazlası. Kaliteli ürünler, hızlı teslimat.',
    button_text: 'Ürünleri İncele',
    button_link: '/products',
    image_url: '/images/slider1.jpg',
    display_order: 1,
    active: true
  },
  {
    title: 'Özel Tasarım Menü Kapları',
    subtitle: 'Deri ve ahşap menü kaplarımızla işletmenize profesyonel bir görünüm kazandırın. Kişiye özel baskı seçenekleri mevcuttur.',
    button_text: 'Menü Kapları',
    button_link: '/menu-kabi-modelleri',
    image_url: '/images/slider2.jpg',
    display_order: 2,
    active: true
  },
  {
    title: '%20 İndirimli Ürünler',
    subtitle: 'Seçili ürünlerde %20\'ye varan indirimler. Kampanya süresi sınırlıdır, fırsatı kaçırmayın!',
    button_text: 'Kampanyalı Ürünler',
    button_link: '/products?sale=true',
    image_url: '/images/slider3.jpg',
    display_order: 3,
    active: true
  }
]

sliders_data.each do |slider_data|
  slider = Slider.find_or_initialize_by(title: slider_data[:title])
  slider.update!(slider_data)
  puts "Created slider: #{slider.title}"
end

puts "\n✅ Seeding completed successfully!"
puts "Total sliders: #{Slider.count}"
