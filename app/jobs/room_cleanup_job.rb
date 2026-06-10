class RoomCleanupJob < ApplicationJob
  queue_as :low

  def perform
    idle_minutes = ENV.fetch("ROOM_CLEANUP_IDLE_MINUTES", 5).to_i
    GameRoom.waiting.where("updated_at < ?", idle_minutes.minutes.ago)
            .where("id NOT IN (?)", RoomPlayer.active_status.select(:room_id))
            .update_all(status: "cancelled")
  end
end
