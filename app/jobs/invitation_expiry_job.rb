class InvitationExpiryJob < ApplicationJob
  queue_as :low

  def perform(invitation_id)
    invitation = Invitation.find_by(id: invitation_id)
    invitation&.expire! if invitation&.status == "pending"
  end
end
