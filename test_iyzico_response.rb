require_relative 'config/environment'

order = Orders::Order.last
service = Payment::IyzicoService.new
result = service.initialize_checkout(order, "http://localhost:3001/api/v1/payments/callback")

puts "Status: #{result['status']}"
puts "Error: #{result['errorMessage']}" if result['errorMessage']
puts "HTML Content Length: #{result['checkoutFormContent']&.length || 0}"
puts "Page URL: #{result['paymentPageUrl']}"
puts "Token: #{result['token']}"
puts "\n--- HTML Content (first 500 chars) ---"
puts result['checkoutFormContent']&.slice(0, 500)
