# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_10_000016) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "contact_syncs", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "phone_hash", null: false
    t.bigint "matched_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["matched_user_id"], name: "index_contact_syncs_on_matched_user_id"
    t.index ["phone_hash"], name: "index_contact_syncs_on_phone_hash"
    t.index ["user_id", "phone_hash"], name: "index_contact_syncs_on_user_id_and_phone_hash", unique: true
    t.index ["user_id"], name: "index_contact_syncs_on_user_id"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.string "platform", null: false
    t.string "device_uid", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["platform"], name: "index_devices_on_platform"
    t.index ["token"], name: "index_devices_on_token"
    t.index ["user_id", "device_uid"], name: "index_devices_on_user_id_and_device_uid", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.bigint "requester_id", null: false
    t.bigint "receiver_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "index_friendships_on_receiver_id"
    t.index ["requester_id", "receiver_id"], name: "index_friendships_on_requester_id_and_receiver_id", unique: true
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
    t.index ["status"], name: "index_friendships_on_status"
  end

  create_table "game_moves", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "player_id", null: false
    t.integer "round_number", default: 1, null: false
    t.integer "trick_number", default: 0, null: false
    t.integer "move_seq", null: false
    t.string "card_played", null: false
    t.string "move_type", default: "play", null: false
    t.boolean "is_cut", default: false, null: false
    t.boolean "won_trick", default: false, null: false
    t.datetime "played_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["is_cut"], name: "index_game_moves_on_is_cut"
    t.index ["match_id", "move_seq"], name: "index_game_moves_on_match_id_and_move_seq", unique: true
    t.index ["match_id", "trick_number"], name: "index_game_moves_on_match_id_and_trick_number"
    t.index ["match_id"], name: "index_game_moves_on_match_id"
    t.index ["played_at"], name: "index_game_moves_on_played_at"
    t.index ["player_id"], name: "index_game_moves_on_player_id"
  end

  create_table "game_rooms", force: :cascade do |t|
    t.bigint "host_id", null: false
    t.string "code", null: false
    t.string "status", default: "waiting", null: false
    t.string "room_type", default: "public", null: false
    t.integer "max_players", default: 4, null: false
    t.integer "min_players", default: 2, null: false
    t.integer "bet_coins", default: 0, null: false
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_game_rooms_on_code", unique: true
    t.index ["config"], name: "index_game_rooms_on_config", using: :gin
    t.index ["host_id"], name: "index_game_rooms_on_host_id"
    t.index ["room_type"], name: "index_game_rooms_on_room_type"
    t.index ["status"], name: "index_game_rooms_on_status"
  end

  create_table "group_members", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "user_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "joined_at", default: -> { "now()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "user_id"], name: "index_group_members_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_members_on_group_id"
    t.index ["role"], name: "index_group_members_on_role"
    t.index ["user_id"], name: "index_group_members_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "avatar_url"
    t.string "group_type", default: "private", null: false
    t.string "invite_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_type"], name: "index_groups_on_group_type"
    t.index ["invite_code"], name: "index_groups_on_invite_code", unique: true, where: "(invite_code IS NOT NULL)"
    t.index ["owner_id"], name: "index_groups_on_owner_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.bigint "sender_id", null: false
    t.bigint "receiver_id", null: false
    t.bigint "room_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_invitations_on_expires_at"
    t.index ["receiver_id"], name: "index_invitations_on_receiver_id"
    t.index ["room_id"], name: "index_invitations_on_room_id"
    t.index ["sender_id", "receiver_id", "room_id"], name: "index_invitations_on_sender_id_and_receiver_id_and_room_id", unique: true
    t.index ["sender_id"], name: "index_invitations_on_sender_id"
    t.index ["status"], name: "index_invitations_on_status"
  end

  create_table "match_players", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "user_id", null: false
    t.integer "seat_position", null: false
    t.boolean "is_donkey", default: false, null: false
    t.integer "final_rank"
    t.integer "tricks_won", default: 0, null: false
    t.integer "cards_at_end", default: 0, null: false
    t.integer "coins_wagered", default: 0, null: false
    t.integer "coins_won", default: 0, null: false
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["final_rank"], name: "index_match_players_on_final_rank"
    t.index ["is_donkey"], name: "index_match_players_on_is_donkey"
    t.index ["match_id", "user_id"], name: "index_match_players_on_match_id_and_user_id", unique: true
    t.index ["match_id"], name: "index_match_players_on_match_id"
    t.index ["user_id"], name: "index_match_players_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "game_room_id", null: false
    t.bigint "winner_id"
    t.string "status", default: "active", null: false
    t.integer "current_trick", default: 0, null: false
    t.integer "current_round", default: 1, null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.jsonb "game_state", default: {}, null: false
    t.jsonb "replay_data", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_room_id"], name: "index_matches_on_game_room_id"
    t.index ["game_state"], name: "index_matches_on_game_state", using: :gin
    t.index ["status"], name: "index_matches_on_status"
    t.index ["winner_id"], name: "index_matches_on_winner_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "actor_id"
    t.string "notif_type", null: false
    t.string "title", null: false
    t.text "body"
    t.jsonb "payload", default: {}, null: false
    t.boolean "read", default: false, null: false
    t.datetime "sent_at", default: -> { "now()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notif_type"], name: "index_notifications_on_notif_type"
    t.index ["payload"], name: "index_notifications_on_payload", using: :gin
    t.index ["sent_at"], name: "index_notifications_on_sent_at"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "player_statistics", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "total_games", default: 0, null: false
    t.integer "wins", default: 0, null: false
    t.integer "losses", default: 0, null: false
    t.integer "donkey_count", default: 0, null: false
    t.integer "tricks_won", default: 0, null: false
    t.integer "win_streak", default: 0, null: false
    t.integer "best_streak", default: 0, null: false
    t.integer "avg_game_duration", default: 0, null: false
    t.integer "total_coins_won", default: 0, null: false
    t.integer "total_coins_lost", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["best_streak"], name: "index_player_statistics_on_best_streak"
    t.index ["donkey_count"], name: "index_player_statistics_on_donkey_count"
    t.index ["user_id"], name: "index_player_statistics_on_user_id", unique: true
    t.index ["win_streak"], name: "index_player_statistics_on_win_streak"
    t.index ["wins"], name: "index_player_statistics_on_wins"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_hash", null: false
    t.datetime "expires_at", null: false
    t.boolean "revoked", default: false, null: false
    t.string "device_uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["token_hash"], name: "index_refresh_tokens_on_token_hash", unique: true
    t.index ["user_id", "revoked"], name: "index_refresh_tokens_on_user_id_and_revoked"
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "room_players", force: :cascade do |t|
    t.bigint "room_id", null: false
    t.bigint "user_id", null: false
    t.integer "seat_position", null: false
    t.string "status", default: "active", null: false
    t.boolean "ready", default: false, null: false
    t.datetime "joined_at", default: -> { "now()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["room_id", "seat_position"], name: "index_room_players_on_room_id_and_seat_position", unique: true
    t.index ["room_id", "user_id"], name: "index_room_players_on_room_id_and_user_id", unique: true
    t.index ["room_id"], name: "index_room_players_on_room_id"
    t.index ["status"], name: "index_room_players_on_status"
    t.index ["user_id"], name: "index_room_players_on_user_id"
  end

  create_table "user_presences", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "status", default: "offline", null: false
    t.datetime "last_seen_at", default: -> { "now()" }, null: false
    t.bigint "current_room_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_room_id"], name: "index_user_presences_on_current_room_id"
    t.index ["last_seen_at"], name: "index_user_presences_on_last_seen_at"
    t.index ["status"], name: "index_user_presences_on_status"
    t.index ["user_id"], name: "index_user_presences_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "phone"
    t.string "email"
    t.string "username", null: false
    t.string "password_digest"
    t.string "display_name"
    t.string "avatar_url"
    t.boolean "is_guest", default: false, null: false
    t.boolean "verified", default: false, null: false
    t.integer "coins", default: 1000, null: false
    t.integer "xp", default: 0, null: false
    t.integer "level", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["is_guest"], name: "index_users_on_is_guest"
    t.index ["level"], name: "index_users_on_level"
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "(phone IS NOT NULL)"
    t.index ["username"], name: "index_users_on_username", unique: true
    t.index ["verified"], name: "index_users_on_verified"
  end

  add_foreign_key "contact_syncs", "users"
  add_foreign_key "contact_syncs", "users", column: "matched_user_id"
  add_foreign_key "devices", "users"
  add_foreign_key "friendships", "users", column: "receiver_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "game_moves", "matches"
  add_foreign_key "game_moves", "users", column: "player_id"
  add_foreign_key "game_rooms", "users", column: "host_id"
  add_foreign_key "group_members", "groups"
  add_foreign_key "group_members", "users"
  add_foreign_key "groups", "users", column: "owner_id"
  add_foreign_key "invitations", "game_rooms", column: "room_id"
  add_foreign_key "invitations", "users", column: "receiver_id"
  add_foreign_key "invitations", "users", column: "sender_id"
  add_foreign_key "match_players", "matches"
  add_foreign_key "match_players", "users"
  add_foreign_key "matches", "game_rooms"
  add_foreign_key "matches", "users", column: "winner_id"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "player_statistics", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "room_players", "game_rooms", column: "room_id"
  add_foreign_key "room_players", "users"
  add_foreign_key "user_presences", "game_rooms", column: "current_room_id"
  add_foreign_key "user_presences", "users"
end
