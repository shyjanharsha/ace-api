module Api
  module V1
    class ContactsController < ApplicationController
      before_action :authenticate_user!

      # POST /api/v1/contacts/sync
      # Body: { phone_numbers: ["+919876543210", ...] }
      def sync
        numbers = params.require(:phone_numbers)
        raise Errors::UnprocessableEntity, "Too many contacts (max 500)" if numbers.size > 500

        hashes = numbers.map { |p| Digest::SHA256.hexdigest(normalize(p)) }

        # Find existing users by phone hash
        # Users store phone in plain, so we hash all phones and compare
        # Build a lookup: phone_hash => user_id
        all_user_phones = User.where.not(phone: nil).pluck(:id, :phone)
        phone_lookup = all_user_phones.each_with_object({}) do |(uid, phone), h|
          h[Digest::SHA256.hexdigest(normalize(phone))] = uid
        end

        results = []
        hashes.each do |hash|
          matched_uid = phone_lookup[hash]
          ContactSync.find_or_create_by!(user_id: current_user.id, phone_hash: hash) do |cs|
            cs.matched_user_id = matched_uid
          end

          if matched_uid && matched_uid != current_user.id
            user = User.find(matched_uid)
            results << {
              phone_hash:   hash,
              user_id:      user.id,
              username:     user.username,
              display_name: user.display_name,
              avatar_url:   user.avatar_url,
              is_friend:    Friendship.involving(current_user.id)
                              .where("requester_id = ? OR receiver_id = ?", matched_uid, matched_uid)
                              .accepted.exists?
            }
          end
        end

        render_success({ matched_contacts: results, total_synced: hashes.size })
      end

      private

      def normalize(phone)
        phone.gsub(/\D/, "").then { |p| p.start_with?("91") ? p : "91#{p}" }
      end
    end
  end
end
