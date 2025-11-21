# Create a test slide
puts "Creating test slide..."

Slider.create!(
  title: "Yeni Sezon Menü Kapları",
  subtitle: "Restoranınız için şık ve dayanıklı çözümler",
  button_text: "İncele",
  button_link: "/products",
  image_url: "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?q=80&w=2070&auto=format&fit=crop",
  display_order: 1,
  active: true
)

puts "Test slide created successfully!"
