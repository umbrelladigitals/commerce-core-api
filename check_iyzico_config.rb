puts "Checking Iyzico Configuration..."
puts "ENV['IYZICO_API_KEY']: #{ENV['IYZICO_API_KEY'].present? ? 'Present' : 'Missing'}"
puts "ENV['IYZICO_SECRET_KEY']: #{ENV['IYZICO_SECRET_KEY'].present? ? 'Present' : 'Missing'}"
puts "ENV['IYZICO_BASE_URL']: #{ENV['IYZICO_BASE_URL']}"

puts "\nChecking Settings from DB..."
api_key = Setting.get('iyzico_api_key', ENV['IYZICO_API_KEY'])
secret_key = Setting.get('iyzico_secret_key', ENV['IYZICO_SECRET_KEY'])
base_url = Setting.get('iyzico_base_url', ENV['IYZICO_BASE_URL'])

puts "Resolved API Key: #{api_key.present? ? 'Present' : 'Missing'}"
puts "Resolved Secret Key: #{secret_key.present? ? 'Present' : 'Missing'}"
puts "Resolved Base URL: #{base_url}"

if api_key.present?
  puts "API Key Length: #{api_key.length}"
  puts "API Key First 4 chars: #{api_key[0..3]}"
end
