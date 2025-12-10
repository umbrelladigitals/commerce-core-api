source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Cloud Storage (Cloudflare R2 / AWS S3)
gem "aws-sdk-s3", require: false

# Authentication
gem "devise"
gem "devise-jwt"

# Authorization
gem "pundit"

# Money management
gem "money-rails"

# Pagination
gem "kaminari"

# Background jobs
gem "sidekiq"
gem "redis", ">= 4.0.1"

# API Documentation
gem "rswag"
gem "rswag-api"
gem "rswag-ui"

# CORS
gem "rack-cors"

# Payment Gateway
gem "iyzipay", path: "vendor/gems/iyzipay"

# Environment variables
gem "dotenv-rails", groups: [:development, :test]

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # RSpec for testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
  
  # Swagger/rswag for specs
  gem "rswag-specs"
end


