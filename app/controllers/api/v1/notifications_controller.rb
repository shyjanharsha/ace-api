module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/notifications
      def index
        pagy, notifs = pagy(current_user.notifications.recent, items: 30)
        render_success(notifs.map { |n| notif_payload(n) }, meta: pagy_meta(pagy))
      end

      # PATCH /api/v1/notifications/mark_read
      def mark_read
        if params[:notification_id]
          notif = current_user.notifications.find(params[:notification_id])
          notif.mark_read!
        else
          Notification.mark_all_read!(current_user.id)
        end
        render_success({ message: "Marked as read" })
      end

      private

      def notif_payload(n)
        {
          id:         n.id,
          type:       n.notif_type,
          title:      n.title,
          body:       n.body,
          payload:    n.payload,
          read:       n.read,
          actor_id:   n.actor_id,
          sent_at:    n.sent_at.iso8601
        }
      end
    end
  end
end
