# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, env|
      # Allow localhost for development
      if Rails.env.development? || Rails.env.test?
        true
      else
        # In production, check against allowed origins from ENV
        allowed_origins = ENV.fetch('CORS_ALLOWED_ORIGINS', '').split(',')
        allowed_origins.any? { |origin| source == origin.strip }
      end
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,
      expose: ['X-Guest-Cart-Id']
  end
end
