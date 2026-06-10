module Api
  module V1
    class GroupsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_group, only: [:show, :update, :destroy]
      before_action :require_owner_or_admin, only: [:update, :destroy]

      # GET /api/v1/groups
      def index
        groups = current_user.groups.includes(:owner)
        render_success(groups.map { |g| group_payload(g) })
      end

      # POST /api/v1/groups
      def create
        group = Group.new(group_params)
        group.owner = current_user

        Group.transaction do
          group.save!
          # Creator is automatically an admin member
          GroupMember.create!(group: group, user: current_user, role: "admin", joined_at: Time.current)
        end

        render_created(group_payload(group))
      end

      # GET /api/v1/groups/:id
      def show
        # Verify user belongs to the group
        raise Errors::Forbidden, "Not a member of this group" unless @group.members.include?(current_user)
        render_success(group_details_payload(@group))
      end

      # PATCH /api/v1/groups/:id
      def update
        @group.update!(group_params)
        render_success(group_payload(@group))
      end

      # DELETE /api/v1/groups/:id
      def destroy
        @group.destroy!
        render_success({ message: "Group deleted successfully" })
      end

      private

      def set_group
        @group = Group.find(params[:id])
      end

      def require_owner_or_admin
        unless @group.owner_id == current_user.id || @group.admin?(current_user)
          raise Errors::Forbidden, "Only owners or admins can modify this group"
        end
      end

      def group_params
        params.permit(:name, :description, :avatar_url, :group_type)
      end

      def group_payload(g)
        {
          id:           g.id,
          name:         g.name,
          description:  g.description,
          avatar_url:   g.avatar_url,
          group_type:   g.group_type,
          invite_code:  g.invite_code,
          owner_id:     g.owner_id,
          owner_name:   g.owner.username,
          members_count: g.members.count,
          created_at:   g.created_at.iso8601
        }
      end

      def group_details_payload(g)
        payload = group_payload(g)
        payload[:members] = g.group_members.includes(:user).map do |gm|
          {
            id:         gm.id,
            user_id:    gm.user.id,
            username:   gm.user.username,
            display_name: gm.user.display_name,
            avatar_url: gm.user.avatar_url,
            role:       gm.role,
            joined_at:  gm.joined_at.iso8601
          }
        end
        payload
      end
    end
  end
end
