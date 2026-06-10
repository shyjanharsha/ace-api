class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string  :phone,            null: true
      t.string  :email,            null: true
      t.string  :username,         null: false
      t.string  :password_digest,  null: true  # null for guest accounts
      t.string  :display_name
      t.string  :avatar_url
      t.boolean :is_guest,         default: false, null: false
      t.boolean :verified,         default: false, null: false
      t.integer :coins,            default: 1000,  null: false
      t.integer :xp,               default: 0,     null: false
      t.integer :level,            default: 1,     null: false

      t.timestamps
    end

    add_index :users, :phone,    unique: true, where: "phone IS NOT NULL"
    add_index :users, :email,    unique: true, where: "email IS NOT NULL"
    add_index :users, :username, unique: true
    add_index :users, :is_guest
    add_index :users, :verified
    add_index :users, :level
  end
end
