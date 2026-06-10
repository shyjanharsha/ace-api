module Api
  module V1
    module Auth
      class GuestsController < ApplicationController
        # POST /api/v1/auth/guest
        def create
          result = ::Auth::GuestService.new.call
          render_created({
            user:   {
              id:           result[:user].id,
              username:     result[:user].username,
              display_name: result[:user].display_name,
              is_guest:     true,
              coins:        result[:user].coins
            },
            tokens: result[:tokens]
          })
        end
      end
    end
  end
end
