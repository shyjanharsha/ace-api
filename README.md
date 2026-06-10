# Kazhutha Kali API (Donkey Card Game Backend)

This is the production-ready, server-authoritative Rails API backend for the **Kazhutha Kali (Donkey Card Game)** multiplayer game.

---

## 🚀 Getting Started

### 1. Environment Configuration
Copy the template environment file and fill in your local credentials:
```bash
cp .env.example .env
```
Open `.env` and configure your `DATABASE_URL` and `REDIS_URL`. 
* Example for local Postgres: `DATABASE_URL=postgresql://postgres:password@localhost:5432/kazhutha_kali_development`

---

## 🐳 Option 1: Running with Docker (Recommended)

Start the entire stack (Rails API, PostgreSQL, Redis, Sidekiq) with a single command:
```bash
docker compose up --build
```

### Useful Docker Commands:
* **Stop the stack**: `docker compose down`
* **Run migrations**: `docker compose run api bundle exec rails db:migrate`
* **Access Rails Console**: `docker compose run api bundle exec rails console`
* **Run RSpec tests**: `docker compose run api bundle exec rspec`
* **Reset Database**: `docker compose run api bundle exec rails db:reset`

---

## 💻 Option 2: Running Locally (Natively)

Ensure you have **Ruby 3.3.x**, **PostgreSQL**, and **Redis** running on your host machine.

### 1. Install dependencies
```bash
bundle install
```

### 2. Setup the Database
```bash
bundle exec rails db:create db:migrate
```

### 3. Start the Services
You need to run the Rails server, Redis server, and Sidekiq worker.

* **Start Rails Server**:
  ```bash
  bundle exec rails server -p 3000
  ```
* **Start Sidekiq (for background jobs)**:
  ```bash
  bundle exec sidekiq -C config/sidekiq.yml
  ```
* **Ensure Redis is running**:
  ```bash
  redis-server
  ```

---

## 🛠️ Essential Commands Reference

| Action | Native Command | Docker Command |
|---|---|---|
| **Rails Console** | `bundle exec rails console` or `rails c` | `docker compose run api rails c` |
| **Run Migrations** | `bundle exec rails db:migrate` | `docker compose run api rails db:migrate` |
| **Rollback Migration** | `bundle exec rails db:rollback` | `docker compose run api rails db:rollback` |
| **Drop Database** | `bundle exec rails db:drop` | `docker compose run api rails db:drop` |
| **Seed Database** | `bundle exec rails db:seed` | `docker compose run api rails db:seed` |
| **Database Reset** | `bundle exec rails db:drop db:create db:migrate db:seed` | `docker compose run api rails db:drop db:create db:migrate db:seed` |
| **Run Test Suite** | `bundle exec rspec` | `docker compose run api rspec` |
| **View Sidekiq Jobs** | Access dashboard at `http://localhost:3000/sidekiq` | Access dashboard at `http://localhost:3000/sidekiq` |

---

## 🔌 WebSocket Details
The ActionCable WebSocket endpoint is mounted at:
```
ws://localhost:3000/cable
```
To authenticate WebSockets, pass the JWT access token in the headers (`Authorization: Bearer <token>`) or as a query parameter (`?token=<token>`).
