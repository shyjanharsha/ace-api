module Api
  module V1
    class UsersController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/users
      def index
        query = params[:query]
        if query.present?
          users = User.where("username LIKE ? OR display_name LIKE ?", "%#{query}%", "%#{query}%")
                      .where.not(id: current_user.id)
                      .limit(20)
        else
          users = User.where.not(id: current_user.id).limit(10)
        end
        render_success(users.map { |u| public_user_payload(u) })
      end

      # GET /api/v1/users/me
      def me
        render_success(user_payload(current_user))
      end

      # PATCH /api/v1/users/me
      def update_me
        current_user.update!(update_params)
        render_success(user_payload(current_user))
      end

      # GET /api/v1/users/:id
      def show
        user = User.find(params[:id])
        render_success(public_user_payload(user))
      end

      # GET /api/v1/users/:id/statistics
      def statistics
        user  = User.find(params[:id])
        stats = user.player_statistic
        render_success({
          user_id:          user.id,
          username:         user.username,
          total_games:      stats.total_games,
          wins:             stats.wins,
          losses:           stats.losses,
          donkey_count:     stats.donkey_count,
          win_rate:         stats.win_rate,
          donkey_rate:      stats.donkey_rate,
          win_streak:       stats.win_streak,
          best_streak:      stats.best_streak,
          tricks_won:       stats.tricks_won,
          avg_game_minutes: (stats.avg_game_duration / 60.0).round(1),
          total_coins_won:  stats.total_coins_won
        })
      end

      # GET /api/v1/users/:id/matches (or /api/v1/users/me/matches)
      def matches
        user_id = params[:id] == "me" ? current_user.id : params[:id]
        pagy, match_players = pagy(
          MatchPlayer.where(user_id: user_id).includes(:match).order("matches.created_at DESC"),
          items: 20
        )
        render_success(match_players.map { |mp| match_summary(mp) }, meta: pagy_meta(pagy))
      end

      private

      def update_params
        params.permit(:display_name, :avatar_url)
      end

      def user_payload(user)
        {
          id:           user.id,
          username:     user.username,
          display_name: user.display_name,
          email:        user.email,
          phone:        user.phone,
          avatar_url:   user.avatar_url,
          is_guest:     user.is_guest,
          verified:     user.verified,
          coins:        user.coins,
          xp:           user.xp,
          level:        user.level,
          status:       user.user_presence&.status || "offline"
        }
      end

      def public_user_payload(user)
        user_payload(user).except(:email, :phone)
      end

      def match_summary(mp)
        {
          match_id:     mp.match_id,
          played_at:    mp.match.created_at.iso8601,
          is_donkey:    mp.is_donkey,
          final_rank:   mp.final_rank,
          tricks_won:   mp.tricks_won,
          coins_won:    mp.coins_won,
          match_status: mp.match.status
        }
      end
    end
  end
end
