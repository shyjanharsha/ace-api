module Api
  module V1
    class GroupMembersController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group

      # POST /api/v1/groups/:group_id/members
      def create
        # Join by invite code or add by user_id (admin only)
        if params[:invite_code].present?
          invite_code = params[:invite_code].to_s.strip.upcase
          raise Errors::UnprocessableEntity, "Invalid invite code" if @group.invite_code != invite_code
          
          member = GroupMember.find_or_initialize_by(group: @group, user: current_user)
          member.role = "member"
          member.joined_at = Time.current
          member.save!

          render_created(member_payload(member))
        elsif params[:user_id].present?
          # Requester must be group owner or admin to add others
          unless @group.owner_id == current_user.id || @group.admin?(current_user)
            raise Errors::Forbidden, "Only owners or admins can add members"
          end

          user = User.find(params[:user_id])
          member = GroupMember.find_or_initialize_by(group: @group, user: user)
          member.role = "member"
          member.joined_at = Time.current
          member.save!

          # Notify user
          Notification.create!(
            user_id: user.id, actor_id: current_user.id,
            notif_type: "group_invite", title: "Group Invite",
            body: "#{current_user.username} added you to the group #{@group.name}",
            payload: { group_id: @group.id }, sent_at: Time.current
          )

          render_created(member_payload(member))
        else
          # Fallback: Join current user to the group directly if public group
          raise Errors::Forbidden, "Cannot join private group directly" if @group.group_type_private?

          member = GroupMember.find_or_initialize_by(group: @group, user: current_user)
          member.role = "member"
          member.joined_at = Time.current
          member.save!

          render_created(member_payload(member))
        end
      end

      # DELETE /api/v1/groups/:group_id/members/:id
      def destroy
        member = @group.group_members.find(params[:id])

        # Permission logic:
        # 1. A member can leave by destroying their own membership
        # 2. An owner or admin can destroy someone else's membership (kick)
        is_self = member.user_id == current_user.id
        is_privileged = @group.owner_id == current_user.id || @group.admin?(current_user)

        unless is_self || is_privileged
          raise Errors::Forbidden, "You do not have permission to remove this member"
        end

        # Owner cannot leave the group unless they delete the group or transfer ownership
        if is_self && @group.owner_id == current_user.id
          raise Errors::UnprocessableEntity, "Owner cannot leave the group. Delete the group instead."
        end

        member.destroy!
        render_success({ message: is_self ? "Left the group" : "Member removed" })
      end

      private

      def set_group
        @group = Group.find(params[:group_id])
      end

      def member_payload(gm)
        {
          id:         gm.id,
          group_id:   gm.group_id,
          user_id:    gm.user_id,
          username:   gm.user.username,
          display_name: gm.user.display_name,
          avatar_url: gm.user.avatar_url,
          role:       gm.role,
          joined_at:  gm.joined_at.iso8601
        }
      end
    end
  end
end
