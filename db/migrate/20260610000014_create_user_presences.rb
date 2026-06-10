class CreateUserPresences < ActiveRecord::Migration[7.1]
  def change
    create_table :user_presences do |t|
      t.references :user,            null: false, foreign_key: true, index: { unique: true }
      t.string     :status,          null: false, default: "offline"
      # status: online | away | in_game | offline
      t.datetime   :last_seen_at,    null: false, default: -> { "NOW()" }
      t.references :current_room,    null: true, foreign_key: { to_table: :game_rooms }

      t.timestamps
    end

    add_index :user_presences, :status
    add_index :user_presences, :last_seen_at
  end
end
