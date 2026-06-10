class CreateMatchPlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :match_players do |t|
      t.references :match,         null: false, foreign_key: true
      t.references :user,          null: false, foreign_key: true
      t.integer    :seat_position, null: false
      t.boolean    :is_donkey,     default: false, null: false
      t.integer    :final_rank     # 1st, 2nd, etc. to finish safely (donkey = last)
      t.integer    :tricks_won,    default: 0, null: false
      t.integer    :cards_at_end,  default: 0, null: false  # cards left when game ended
      t.integer    :coins_wagered, default: 0, null: false
      t.integer    :coins_won,     default: 0, null: false   # negative = lost
      t.datetime   :finished_at   # when this player safely exited

      t.timestamps
    end

    add_index :match_players, [:match_id, :user_id], unique: true
    add_index :match_players, :is_donkey
    add_index :match_players, :final_rank
  end
end
