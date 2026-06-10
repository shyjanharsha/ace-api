class CreateRefreshTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :refresh_tokens do |t|
      t.references :user,        null: false, foreign_key: true
      t.string     :token_hash,  null: false  # SHA256 of the actual token
      t.datetime   :expires_at,  null: false
      t.boolean    :revoked,     default: false, null: false
      t.string     :device_uid                 # which device this belongs to

      t.timestamps
    end

    add_index :refresh_tokens, :token_hash, unique: true
    add_index :refresh_tokens, [:user_id, :revoked]
    add_index :refresh_tokens, :expires_at
  end
end
