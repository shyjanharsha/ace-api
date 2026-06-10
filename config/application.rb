require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module KazhuthaKaliApi
  class Application < Rails::Application
    config.load_defaults 7.1

    # API only mode
    config.api_only = true

    # Time zone
    config.time_zone = "Chennai"
    config.active_record.default_timezone = :utc

    # Autoload lib and app/services
    config.autoload_lib(ignore: %w[assets tasks])
    config.autoload_paths += %W[#{config.root}/app/services]

    # ActionCable — allow WebSocket connections
    config.action_cable.mount_path = "/cable"
    config.action_cable.allowed_request_origins = [
      /http:\/\/localhost:\d+/,
      /https:\/\/.*/
    ]

    # Active Job — use Sidekiq
    config.active_job.queue_adapter = :sidekiq

    # Middleware — Rack::Attack
    config.middleware.use Rack::Attack

    # Log level
    config.log_level = :info

    # Eager load in production
    config.eager_load_paths << Rails.root.join("app/services")
    config.eager_load_paths << Rails.root.join("app/channels")
  end
end
