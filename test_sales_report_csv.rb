require 'net/http'
require 'json'

puts "📊 Testing Sales Report CSV Export"

# Login
user = User.find_by(email: 'admin@example.com')
token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

puts "User: #{user.email}"
puts "Token: #{token[0..20]}....\n"

# Test CSV format
uri = URI('http://localhost:3000/api/reports/sales?format=csv')
request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bearer #{token}"

puts "🔗 Making request to /api/reports/sales?format=csv..."

response = Net::HTTP.start(uri.hostname, uri.port) do |http|
  http.request(request)
end

puts "Status: #{response.code}"
puts "Content-Type: #{response['Content-Type']}"
puts "Content-Disposition: #{response['Content-Disposition']}\n"

if response.code == '200'
  puts "✅ SUCCESS!"
  puts "\n📄 CSV Content (first 500 chars):"
  puts response.body[0..500]
  puts "..."
else
  puts "\n❌ ERROR:"
  puts response.body
end
