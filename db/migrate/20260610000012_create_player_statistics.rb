class CreatePlayerStatistics < ActiveRecord::Migration[7.1]
  def change
    create_table :player_statistics do |t|
      t.references :user,              null: false, foreign_key: true, index: { unique: true }
      t.integer    :total_games,       default: 0, null: false
      t.integer    :wins,              default: 0, null: false
      t.integer    :losses,            default: 0, null: false
      t.integer    :donkey_count,      default: 0, null: false
      t.integer    :tricks_won,        default: 0, null: false
      t.integer    :win_streak,        default: 0, null: false
      t.integer    :best_streak,       default: 0, null: false
      t.integer    :avg_game_duration, default: 0, null: false  # seconds
      t.integer    :total_coins_won,   default: 0, null: false
      t.integer    :total_coins_lost,  default: 0, null: false

      t.timestamps
    end

    add_index :player_statistics, :wins
    add_index :player_statistics, :donkey_count
    add_index :player_statistics, :win_streak
    add_index :player_statistics, :best_streak
  end
end
