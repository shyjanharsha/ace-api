Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # ActionCable WebSocket
  mount ActionCable.server => "/cable"

  # Sidekiq Web UI (password protect in production)
  require "sidekiq/web"
  require "sidekiq-scheduler/web"
  mount Sidekiq::Web => "/sidekiq"

  namespace :api do
    namespace :v1 do
      # -------------------------------------------------------
      # Authentication
      # -------------------------------------------------------
      namespace :auth do
        post   :signup,        to: "registrations#create"
        post   :send_otp,      to: "registrations#send_otp"
        post   :verify_phone,  to: "registrations#verify_phone"
        post   :login,         to: "sessions#create"
        delete :logout,        to: "sessions#destroy"
        post   :guest,         to: "guests#create"
        post   :refresh,       to: "tokens#create"
        post   :devices,       to: "tokens#register_device"
      end

      # -------------------------------------------------------
      # Users
      # -------------------------------------------------------
      get   "users/me",          to: "users#me"
      patch "users/me",          to: "users#update_me"
      get   "users/me/matches",  to: "users#matches", defaults: { id: "me" }

      resources :users, only: [:index, :show] do
        member do
          get :statistics
          get :matches
        end
      end

      # -------------------------------------------------------
      # Rooms
      # -------------------------------------------------------
      resources :rooms do
        member do
          post   :join
          delete :leave
          post   :start
          post   :chat
        end
        collection do
          post :join_by_code
        end
      end

      # -------------------------------------------------------
      # Game (active match)
      # -------------------------------------------------------
      scope "game/:match_id" do
        post :play,      to: "game#play"
        post :reconnect, to: "game#reconnect"
      end

      # -------------------------------------------------------
      # Matches
      # -------------------------------------------------------
      resources :matches, only: [:show] do
        member do
          get :replay
        end
      end

      # -------------------------------------------------------
      # Social
      # -------------------------------------------------------
      resources :friendships

      resources :groups do
        resources :members, only: [:create, :destroy], controller: "group_members"
      end

      post "contacts/sync", to: "contacts#sync"

      # -------------------------------------------------------
      # Invitations
      # -------------------------------------------------------
      resources :invitations, only: [:index, :create, :update]

      # -------------------------------------------------------
      # Notifications
      # -------------------------------------------------------
      get   "notifications",            to: "notifications#index"
      patch "notifications/mark_read",  to: "notifications#mark_read"

      # -------------------------------------------------------
      # Presence (friends online status)
      # -------------------------------------------------------
      get "presences/friends", to: "presences#friends"

      # -------------------------------------------------------
      # Leaderboard
      # -------------------------------------------------------
      get "leaderboard", to: "leaderboard#index"
    end
  end
end
