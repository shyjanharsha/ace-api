class PushNotificationJob < ApplicationJob
  queue_as :default

  # Sends FCM push to all active devices of a user
  def perform(user_id, title:, body:, data: {})
    user    = User.find_by(id: user_id)
    tokens  = user&.devices&.active&.pluck(:token)
    return if tokens.blank?

    fcm     = FCM.new(ENV.fetch("FCM_SERVER_KEY", ""))
    options = {
      notification: { title: title, body: body, sound: "default" },
      data:         data.merge(user_id: user_id.to_s)
    }

    response = fcm.send(tokens, options)
    Rails.logger.info "[PushNotificationJob] user=#{user_id} tokens=#{tokens.size} status=#{response[:status_code]}"
  rescue => e
    Rails.logger.error "[PushNotificationJob] Error: #{e.message}"
  end
end
