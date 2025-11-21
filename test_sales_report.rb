#!/usr/bin/env ruby
# Test sales report endpoint

user = User.first
token = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first

puts "📊 Testing Sales Report Endpoint"
puts "User: #{user.email}"
puts "Token: #{token[0..20]}..."
puts "\n🔗 Making request to /api/reports/sales..."

require 'net/http'
require 'json'

uri = URI('http://localhost:3000/api/reports/sales.json')
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bearer #{token}"

begin
  response = http.request(request)
  puts "Status: #{response.code}"
  
  if response.code == '200'
    data = JSON.parse(response.body)
    puts "\n✅ SUCCESS!"
    puts JSON.pretty_generate(data)
  else
    puts "\n❌ ERROR:"
    puts response.body
  end
rescue => e
  puts "\n❌ Request failed: #{e.message}"
  puts "Make sure rails server is running: rails s"
end
