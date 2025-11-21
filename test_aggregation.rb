#!/usr/bin/env ruby
# Test script for sales aggregation query

order_ids = Orders::Order.where(status: [:paid, :shipped]).pluck(:id)
puts "📦 Found #{order_ids.length} paid/shipped orders: #{order_ids.inspect}"

if order_ids.empty?
  puts "⚠️  No orders to aggregate"
  exit
end

puts "\n🔍 Testing aggregation query..."
begin
  result = Orders::OrderItem.unscoped
    .where(order_id: order_ids)
    .select(
      'SUM(order_items.price_cents * order_items.quantity) as total_revenue',
      'SUM(order_items.quantity) as total_qty',
      'COUNT(DISTINCT order_items.order_id) as orders_count'
    )
    .take
  
  if result
    puts "✅ SUCCESS!"
    puts "   Revenue: #{result.total_revenue} cents (#{Money.new(result.total_revenue.to_i, 'USD').format})"
    puts "   Quantity: #{result.total_qty}"
    puts "   Orders: #{result.orders_count}"
  else
    puts "❌ No result returned"
  end
rescue => e
  puts "❌ ERROR: #{e.class}"
  puts "   Message: #{e.message}"
  puts "   Backtrace: #{e.backtrace.first(3).join("\n   ")}"
end

puts "\n🧪 Alternative approach using .calculate:"
begin
  revenue = Orders::OrderItem.where(order_id: order_ids)
    .sum('price_cents * quantity')
  qty = Orders::OrderItem.where(order_id: order_ids).sum(:quantity)
  count = Orders::Order.where(id: order_ids).count
  
  puts "✅ SUCCESS with .calculate methods!"
  puts "   Revenue: #{revenue} cents (#{Money.new(revenue, 'USD').format})"
  puts "   Quantity: #{qty}"
  puts "   Orders: #{count}"
rescue => e
  puts "❌ ERROR: #{e.message}"
end
