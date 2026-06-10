class PlayerStatistic < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true

  def win_rate
    return 0.0 if total_games.zero?
    (wins.to_f / total_games * 100).round(1)
  end

  def donkey_rate
    return 0.0 if total_games.zero?
    (donkey_count.to_f / total_games * 100).round(1)
  end

  def record_win!(duration_seconds = 0)
    ApplicationRecord.transaction do
      increment!(:wins)
      increment!(:total_games)
      new_streak = win_streak + 1
      update!(
        win_streak: new_streak,
        best_streak: [best_streak, new_streak].max,
        avg_game_duration: calculate_new_avg(duration_seconds)
      )
    end
  end

  def record_loss!(duration_seconds = 0)
    increment!(:losses)
    increment!(:total_games)
    update!(win_streak: 0, avg_game_duration: calculate_new_avg(duration_seconds))
  end

  def record_donkey!(duration_seconds = 0)
    increment!(:donkey_count)
    record_loss!(duration_seconds)
  end

  def record_trick_won!
    increment!(:tricks_won)
  end

  def record_coins_won!(amount)
    increment!(:total_coins_won, by: amount)
  end

  def record_coins_lost!(amount)
    increment!(:total_coins_lost, by: amount)
  end

  private

  def calculate_new_avg(new_duration)
    return new_duration if total_games <= 1
    ((avg_game_duration * (total_games - 1)) + new_duration) / total_games
  end
end
