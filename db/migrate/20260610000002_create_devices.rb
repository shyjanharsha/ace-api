class CreateDevices < ActiveRecord::Migration[7.1]
  def change
    create_table :devices do |t|
      t.references :user,       null: false, foreign_key: true
      t.string     :token,      null: false          # FCM push token
      t.string     :platform,   null: false          # ios / android / web
      t.string     :device_uid, null: false          # unique device identifier
      t.boolean    :active,     default: true, null: false

      t.timestamps
    end

    add_index :devices, :token
    add_index :devices, [:user_id, :device_uid], unique: true
    add_index :devices, :platform
  end
end
