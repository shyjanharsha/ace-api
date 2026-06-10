source "https://rubygems.org"

ruby "3.2.8"

gem "rails", "~> 7.1.3", ">= 7.1.3.2"

# Database
gem "pg", "~> 1.1"

# Web server
gem "puma", ">= 5.0"

# Redis — ActionCable adapter + caching + Sidekiq
gem "redis", ">= 4.0.1"
gem "redis-client"

# Background jobs
gem "connection_pool", "< 3.0.0"
gem "sidekiq", "~> 7.2"
gem "sidekiq-scheduler", "~> 5.0"

# Authentication
gem "jwt", "~> 2.7"
gem "bcrypt", "~> 3.1.7"

# CORS
gem "rack-cors"

# Rate limiting (anti-cheat)
gem "rack-attack"

# Pagination
gem "pagy", "~> 6.2"

# JSON serialization
gem "active_model_serializers", "~> 0.10.14"

# Phone number validation
gem "phonelib"

# Authorization
gem "pundit"

# Firebase Cloud Messaging push notifications
gem "fcm"

# HTTP client (for MSG91 OTP)
gem "faraday", "~> 2.7"

# Environment variables
gem "dotenv-rails"

# Reduces boot times through caching
gem "bootsnap", require: false

# Windows tzinfo
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers", "~> 6.0"
end

group :development do
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "database_cleaner-active_record"
  gem "webmock"
end
