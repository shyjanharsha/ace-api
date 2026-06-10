class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :actor,      null: true,  foreign_key: { to_table: :users }
      t.string     :notif_type, null: false
      # notif_type: friend_request | friend_accepted | game_invite |
      #             game_started | game_over | group_invite | system
      t.string     :title,      null: false
      t.text       :body
      t.jsonb      :payload,    null: false, default: {}
      # payload: { room_id: X, match_id: Y, invitation_id: Z }
      t.boolean    :read,       default: false, null: false
      t.datetime   :sent_at,    null: false, default: -> { "NOW()" }

      t.timestamps
    end

    add_index :notifications, [:user_id, :read]
    add_index :notifications, :notif_type
    add_index :notifications, :sent_at
    add_index :notifications, :payload, using: :gin
  end
end
