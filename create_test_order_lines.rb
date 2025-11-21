#!/usr/bin/env ruby
# Create test order lines for sales report testing

# Find or create products
# Use existing products from seed
product1 = Catalog::Product.first
product2 = Catalog::Product.second

puts "📦 Products:"
puts "  Product 1: #{product1.title} (ID: #{product1.id}) - $#{product1.price_cents / 100.0}"
puts "  Product 2: #{product2.title} (ID: #{product2.id}) - $#{product2.price_cents / 100.0}"

# Find paid order
order = Orders::Order.find(5)
puts "\n🛒 Order ##{order.id} (#{order.status}): $#{order.total_cents / 100.0}"

# Add order lines
line1 = Orders::OrderLine.create!(
  order: order,
  product: product1,
  quantity: 2,
  unit_price_cents: product1.price_cents,
  total_cents: product1.price_cents * 2
)

line2 = Orders::OrderLine.create!(
  order: order,
  product: product2,
  quantity: 1,
  unit_price_cents: product2.price_cents,
  total_cents: product2.price_cents
)

# Update order total
new_total = line1.total_cents + line2.total_cents
order.update!(total_cents: new_total, subtotal_cents: new_total)

puts "\n✅ Created 2 order lines:"
puts "  Line 1: #{line1.quantity}x #{product1.title} = $#{line1.total_cents / 100.0}"
puts "  Line 2: #{line2.quantity}x #{product2.title} = $#{line2.total_cents / 100.0}"
puts "\n💰 Order total: $#{order.reload.total_cents / 100.0}"
