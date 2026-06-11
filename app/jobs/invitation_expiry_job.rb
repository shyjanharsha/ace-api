class InvitationExpiryJob < ApplicationJob
  queue_as :low

  def perform(invitation_id = nil)
    if invitation_id.present?
      invitation = Invitation.find_by(id: invitation_id)
      invitation&.expire! if invitation&.status == "pending"
    else
      # Periodic cron cleanup for all expired invitations
      Invitation.where(status: "pending").where("expires_at <= ?", Time.current).find_each do |inv|
        inv.expire!
      end
    end
  end
end
