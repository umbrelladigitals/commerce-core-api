require 'net/http'
require 'json'

puts "📊 Testing Sales Report Filters"

# Login
user = User.find_by(email: 'admin@example.com')
token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

def test_endpoint(uri_string, token, description)
  uri = URI(uri_string)
  request = Net::HTTP::Get.new(uri)
  request['Authorization'] = "Bearer #{token}"
  
  puts "\n#{description}"
  puts "🔗 #{uri}"
  
  response = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(request)
  end
  
  if response.code == '200'
    data = JSON.parse(response.body)
    summary = data.dig('data', 'summary')
    breakdown = data.dig('data', 'breakdown') || []
    
    puts "✅ Status: #{response.code}"
    puts "   Revenue: #{summary['total_revenue_formatted']}"
    puts "   Quantity: #{summary['total_quantity']}"
    puts "   Products: #{breakdown.count}"
    breakdown.each do |product|
      puts "     - #{product['product_title']}: #{product['revenue_formatted']} (#{product['quantity']} units)"
    end
  else
    puts "❌ Status: #{response.code}"
    puts response.body[0..200]
  end
end

# Test 1: No filters (all data)
test_endpoint(
  'http://localhost:3000/api/reports/sales',
  token,
  "TEST 1: All sales (no filters)"
)

# Test 2: Filter by product
product_id = Catalog::Product.first.id
test_endpoint(
  "http://localhost:3000/api/reports/sales?product_id=#{product_id}",
  token,
  "TEST 2: Filter by product_id=#{product_id}"
)

# Test 3: Date range
test_endpoint(
  'http://localhost:3000/api/reports/sales?start_date=2025-10-01&end_date=2025-10-31',
  token,
  "TEST 3: October 2025 sales"
)

# Test 4: Date range (no results)
test_endpoint(
  'http://localhost:3000/api/reports/sales?start_date=2024-01-01&end_date=2024-01-31',
  token,
  "TEST 4: January 2024 sales (should be empty)"
)

puts "\n✅ All filter tests completed!"
