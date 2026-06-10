class MatchAnalyticsJob < ApplicationJob
  queue_as :default

  # Updates player statistics and distributes coins after a match ends
  def perform(match_id)
    match = Match.find_by(id: match_id)
    return unless match&.status == "completed"

    duration = match.duration_seconds || 0
    bet      = match.game_room.bet_coins
    players  = match.match_players.includes(:user)
    total_pool = bet * players.count

    players.each do |mp|
      user  = mp.user
      stats = user.player_statistic

      next unless stats

      if mp.is_donkey
        # Donkey loses coins
        stats.record_donkey!(duration)
        if bet > 0
          lost = bet
          mp.update!(coins_wagered: bet, coins_won: -lost)
          user.deduct_coins!(lost) rescue nil
        end
      elsif mp.final_rank == 1
        # Winner gets the pool (first to finish safely)
        stats.record_win!(duration)
        if bet > 0
          won = total_pool - bet  # wins everyone else's coins
          mp.update!(coins_wagered: bet, coins_won: won)
          user.add_coins!(won)
        end
      else
        stats.record_loss!(duration)
      end

      stats.record_trick_won! # aggregate separately from move records
      user.add_xp!(calculate_xp(mp))
    end
  end

  private

  def calculate_xp(match_player)
    return 200 if match_player.final_rank == 1
    return 100 unless match_player.is_donkey
    10  # donkey gets minimal XP
  end
end
