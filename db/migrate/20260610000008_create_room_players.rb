class CreateRoomPlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :room_players do |t|
      t.references :room,          null: false, foreign_key: { to_table: :game_rooms }
      t.references :user,          null: false, foreign_key: true
      t.integer    :seat_position, null: false  # 0-indexed seat
      t.string     :status,        null: false, default: "active"
      # status: active | disconnected | left | kicked
      t.boolean    :ready,         default: false, null: false
      t.datetime   :joined_at,     null: false, default: -> { "NOW()" }

      t.timestamps
    end

    add_index :room_players, [:room_id, :user_id],       unique: true
    add_index :room_players, [:room_id, :seat_position], unique: true
    add_index :room_players, :status
  end
end
