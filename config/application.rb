require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module CommerceCoreApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Autoload app/domains for modular domain structure
    config.autoload_paths << Rails.root.join("app/domains")
    config.eager_load_paths << Rails.root.join("app/domains")

    # Use Sidekiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    
    # Session middleware required for Devise
    config.session_store :cookie_store, key: '_commerce_core_api_session'
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use config.session_store, config.session_options

    # Default URL options for URL generation (ActiveStorage, etc.)
    config.action_controller.default_url_options = { host: ENV.fetch('HOST_URL', 'localhost:3000') }
  end
end
