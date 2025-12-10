# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Eager load all domain models
Rails.application.eager_load!

puts "🌱 Starting Seed Process..."

# ============================================================================
# 1. USERS
# ============================================================================
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
  puts "👤 User checked/created: #{user.email}"
end

# ============================================================================
# 2. CATEGORIES
# ============================================================================
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
  { name: 'Hesap Sümenleri', slug: 'hesap-sumenleri', parent: 'Menü Çeşitleri' },
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
  puts "📂 Category checked/created: #{category.name}"
end

# ============================================================================
# 3. PRODUCTS WITH OPTIONS (CONSOLIDATED)
# ============================================================================
products_definitions = [
  {
    title: 'Deri Menü Kabı',
    sku: 'DMK-MAIN',
    category_slug: 'deri-menu-kabi-modelleri',
    price: 45000,
    description: "Premium kalite gerçek deri menü kabı. Restoranlar için şık ve dayanıklı çözüm.\n\nÖzellikler:\n- 1. Sınıf Suni Deri\n- Leke tutmaz, silinebilir\n- Uzun ömürlü kullanım\n- Farklı renk seçenekleri",
    options: [
      {
        name: 'Renk',
        type: 'color',
        values: [
          { name: 'Kahverengi', price: 0, meta: { color: '#8B4513' } },
          { name: 'Siyah', price: 0, meta: { color: '#000000' } },
          { name: 'Bordo', price: 0, meta: { color: '#800000' } },
          { name: 'Taba', price: 0, meta: { color: '#D2691E' } },
          { name: 'Lacivert', price: 0, meta: { color: '#000080' } }
        ]
      },
      {
        name: 'Boyut',
        type: 'select',
        values: [
          { name: 'A4', price: 0 },
          { name: 'A5', price: -5000 },
          { name: 'Kare (20x20)', price: -2000 }
        ]
      },
      {
        name: 'İç Sayfa',
        type: 'select',
        values: [
          { name: '2 Sayfa', price: 0, mode: 'per_unit' },
          { name: '4 Sayfa', price: 5000, mode: 'per_unit' },
          { name: '6 Sayfa', price: 10000, mode: 'per_unit' },
          { name: '8 Sayfa', price: 15000, mode: 'per_unit' },
          { name: '10 Sayfa', price: 20000, mode: 'per_unit' }
        ]
      },
      {
        name: 'Logo Baskı',
        type: 'radio',
        values: [
          { name: 'Baskısız', price: 0 },
          { name: 'Sıcak Baskı', price: 2500, mode: 'flat' }, # Kalıp ücreti (Tek seferlik)
          { name: 'Varak Baskı (Gold)', price: 3500, mode: 'flat' },
          { name: 'Varak Baskı (Gümüş)', price: 3500, mode: 'flat' }
        ]
      }
    ]
  },
  {
    title: 'Ahşap Menü Kabı',
    sku: 'AMK-MAIN',
    category_slug: 'ahsap-menu-kabi-modelleri',
    price: 38000,
    description: "Doğal ahşap dokusuyla mekanınıza sıcaklık katın.\n\nÖzellikler:\n- Doğal Ahşap Kaplama\n- Dayanıklı Vernik\n- Lazer Kazıma Logo İmkanı",
    options: [
      {
        name: 'Ahşap Türü',
        type: 'select',
        values: [
          { name: 'Ceviz', price: 0 },
          { name: 'Bambu', price: -3000 },
          { name: 'Meşe', price: 4000 }
        ]
      },
      {
        name: 'Boyut',
        type: 'select',
        values: [
          { name: 'A4', price: 0 },
          { name: 'A5', price: -4000 }
        ]
      },
      {
        name: 'İç Sayfa',
        type: 'select',
        values: [
          { name: '2 Sayfa', price: 0, mode: 'per_unit' },
          { name: '4 Sayfa', price: 4000, mode: 'per_unit' },
          { name: '6 Sayfa', price: 8000, mode: 'per_unit' }
        ]
      },
      {
        name: 'Logo İşleme',
        type: 'radio',
        values: [
          { name: 'İşlemesiz', price: 0 },
          { name: 'Lazer Kazıma', price: 5000, mode: 'flat' }, # Setup fee
          { name: 'Renkli UV Baskı', price: 7500, mode: 'flat' }
        ]
      }
    ]
  },
  {
    title: 'Sıvama Menü',
    sku: 'SVM-MAIN',
    category_slug: 'sivama-menu',
    price: 12000,
    description: "Ekonomik ve şık sıvama menü çözümleri.\n\nÖzellikler:\n- Sert Kapak\n- Mat veya Parlak Selefon\n- Tam Renkli Baskı",
    options: [
      {
        name: 'Boyut',
        type: 'select',
        values: [
          { name: 'A4', price: 0 },
          { name: 'A3', price: 3000 },
          { name: 'Kare', price: 0 }
        ]
      },
      {
        name: 'Laminasyon',
        type: 'select',
        values: [
          { name: 'Mat Selefon', price: 0 },
          { name: 'Parlak Selefon', price: 0 },
          { name: 'Kadife Selefon', price: 2000, mode: 'per_unit' }
        ]
      },
      {
        name: 'Sayfa Sayısı',
        type: 'select',
        values: [
          { name: '2 Sayfa (Tek Yaprak)', price: 0 },
          { name: '4 Sayfa (Kapalı)', price: 3000, mode: 'per_unit' },
          { name: '6 Sayfa (Kırımlı)', price: 6000, mode: 'per_unit' }
        ]
      }
    ]
  },
  {
    title: 'Amerikan Servisi',
    sku: 'AMS-MAIN',
    category_slug: 'amerikan-servisi',
    price: 22000,
    description: "Masanızı koruyan ve şıklık katan amerikan servisleri.",
    options: [
      {
        name: 'Malzeme',
        type: 'select',
        values: [
          { name: 'Suni Deri', price: 6000, mode: 'per_unit' },
          { name: 'Bambu', price: 0 },
          { name: 'Keçe', price: -5000, mode: 'per_unit' }
        ]
      },
      {
        name: 'Renk',
        type: 'color',
        values: [
          { name: 'Kahverengi', price: 0, meta: { color: '#8B4513' } },
          { name: 'Siyah', price: 0, meta: { color: '#000000' } },
          { name: 'Gri', price: 0, meta: { color: '#808080' } },
          { name: 'Krem', price: 0, meta: { color: '#F5F5DC' } }
        ]
      },
      {
        name: 'Set İçeriği',
        type: 'select',
        values: [
          { name: '4 Adet', price: 0 },
          { name: '6 Adet', price: 10000, mode: 'per_unit' }, # Price diff logic might need adjustment based on base price
          { name: '12 Adet', price: 30000, mode: 'per_unit' }
        ]
      }
    ]
  },
  {
    title: 'Hesap Sümeni',
    sku: 'HSM-MAIN',
    category_slug: 'hesap-sumenleri',
    price: 8000,
    description: "Hesap sunumlarınız için şık sümenler.",
    options: [
      {
        name: 'Malzeme',
        type: 'select',
        values: [
          { name: 'Deri', price: 0 },
          { name: 'Ahşap', price: 2000, mode: 'per_unit' }
        ]
      },
      {
        name: 'Renk',
        type: 'color',
        values: [
          { name: 'Siyah', price: 0, meta: { color: '#000000' } },
          { name: 'Kahverengi', price: 0, meta: { color: '#8B4513' } },
          { name: 'Bordo', price: 0, meta: { color: '#800000' } }
        ]
      },
      {
        name: 'Logo',
        type: 'radio',
        values: [
          { name: 'Baskısız', price: 0 },
          { name: 'Baskılı', price: 1500, mode: 'flat' }
        ]
      }
    ]
  }
]

products = {}

products_definitions.each do |prod_def|
  category = Catalog::Category.find_by(slug: prod_def[:category_slug])
  unless category
    puts "⚠️ Category not found for #{prod_def[:title]}: #{prod_def[:category_slug]}"
    next
  end

  product = Catalog::Product.find_or_initialize_by(sku: prod_def[:sku])
  
  product.title = prod_def[:title]
  product.description = prod_def[:description]
  product.price_cents = prod_def[:price]
  product.currency = 'TRY'
  product.active = true
  product.category = category
  product.save!
  
  puts "📦 Product created/updated: #{product.title}"
  products[product.sku] = product

  # Create Options
  if prod_def[:options]
    prod_def[:options].each_with_index do |opt_def, index|
      option = product.product_options.find_or_initialize_by(name: opt_def[:name])
      option.option_type = opt_def[:type]
      option.position = index + 1
      option.save!

      # Create Option Values
      opt_def[:values].each_with_index do |val_def, v_index|
        value = option.product_option_values.find_or_initialize_by(name: val_def[:name])
        value.price_cents = val_def[:price]
        value.price_mode = val_def[:mode] || 'flat'
        value.position = v_index + 1
        value.meta = val_def[:meta] || {}
        value.save!
      end
    end
    puts "   └── Options configured: #{prod_def[:options].map { |o| o[:name] }.join(', ')}"
  end
end

# ============================================================================
# 4. VARIANTS (SAMPLE STOCK KEEPING UNITS)
# ============================================================================
# Note: In a real scenario, you might generate variants for all combinations.
# Here we create some specific ones for stock tracking.

puts "🔢 Creating sample variants..."

deri_menu = products['DMK-MAIN']
if deri_menu
  # Variant 1: Kahverengi, A4, 2 Sayfa, Baskısız
  v1_options = {
    'Renk' => 'Kahverengi',
    'Boyut' => 'A4',
    'İç Sayfa' => '2 Sayfa',
    'Logo Baskı' => 'Baskısız'
  }
  
  Catalog::Variant.create!(
    product: deri_menu,
    sku: 'DMK-KAH-A4-2',
    price_cents: 45000,
    stock: 100,
    options: v1_options
  ) rescue nil # Ignore if exists (sku unique)

  # Variant 2: Siyah, A4, 4 Sayfa, Baskısız
  v2_options = {
    'Renk' => 'Siyah',
    'Boyut' => 'A4',
    'İç Sayfa' => '4 Sayfa',
    'Logo Baskı' => 'Baskısız'
  }
  
  Catalog::Variant.create!(
    product: deri_menu,
    sku: 'DMK-SIY-A4-4',
    price_cents: 50000, # Base + 4 Page cost
    stock: 50,
    options: v2_options
  ) rescue nil
end

# ============================================================================
# 5. SLIDERS
# ============================================================================
puts "🖼️ Creating sliders..."

sliders_data = [
  {
    title: "Yeni Sezon Menü Kapları",
    subtitle: "Restoranınız için şık ve dayanıklı menü kapları",
    image_url: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=2070&auto=format&fit=crop",
    button_text: "Koleksiyonu İncele",
    button_link: "/category/menu-kabi-modelleri",
    display_order: 1,
    active: true
  },
  {
    title: "Özel Tasarım Masa Aksesuarları",
    subtitle: "Mekanınıza değer katan detaylar",
    image_url: "https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=1974&auto=format&fit=crop",
    button_text: "Ürünleri Gör",
    button_link: "/category/masa-aksesuarlari",
    display_order: 2,
    active: true
  },
  {
    title: "Hızlı Teslimat & Güvenli Ödeme",
    subtitle: "Tüm siparişlerinizde güvenli alışveriş deneyimi",
    image_url: "https://images.unsplash.com/photo-1556742049-0cfed4f7a07d?q=80&w=2070&auto=format&fit=crop",
    button_text: "Alışverişe Başla",
    button_link: "/products",
    display_order: 3,
    active: true
  }
]

sliders_data.each do |slider_data|
  Slider.find_or_create_by!(title: slider_data[:title]) do |slider|
    slider.subtitle = slider_data[:subtitle]
    slider.image_url = slider_data[:image_url]
    slider.button_text = slider_data[:button_text]
    slider.button_link = slider_data[:button_link]
    slider.display_order = slider_data[:display_order]
    slider.active = slider_data[:active]
  end
end

puts "✅ Seed process completed successfully!"
