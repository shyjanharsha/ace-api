module Api
  module V1
    class LeaderboardController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/leaderboard?type=wins&period=weekly
      def index
        type   = params.fetch(:type, "wins")
        period = params.fetch(:period, "all_time")

        scope = PlayerStatistic.joins(:user)
                               .where(users: { is_guest: false })

        scope = apply_period(scope, period)

        column = leaderboard_column(type)
        pagy, stats = pagy(scope.order("#{column} DESC").includes(:user), items: 50)

        render_success(stats.map { |s| leaderboard_entry(s, column) }, meta: pagy_meta(pagy))
      end

      private

      def leaderboard_column(type)
        case type
        when "donkeys" then "donkey_count"
        when "streak"  then "best_streak"
        when "coins"   then "total_coins_won"
        else "wins"
        end
      end

      def apply_period(scope, period)
        case period
        when "weekly"
          scope.where("player_statistics.updated_at >= ?", 1.week.ago)
        when "monthly"
          scope.where("player_statistics.updated_at >= ?", 1.month.ago)
        else
          scope
        end
      end

      def leaderboard_entry(stat, column)
        {
          user_id:      stat.user_id,
          username:     stat.user.username,
          display_name: stat.user.display_name,
          avatar_url:   stat.user.avatar_url,
          level:        stat.user.level,
          wins:         stat.wins,
          donkey_count: stat.donkey_count,
          best_streak:  stat.best_streak,
          total_games:  stat.total_games,
          value:        stat.send(column)
        }
      end
    end
  end
end
