module Api
  module V1
    module Auth
      class RegistrationsController < ApplicationController
        # POST /api/v1/auth/signup
        def create
          service = ::Auth::SignupService.new(signup_params)
          user    = service.call

          unless user
            render_error(service.errors.join(", "), status: :unprocessable_entity)
            return
          end

          tokens = ::Auth::JwtService.issue_token_pair(user, device_uid: params[:device_uid])

          render_created({
            user:   user_payload(user),
            tokens: tokens
          })
        end

        # POST /api/v1/auth/verify_phone
        def verify_phone
          result = ::Auth::OtpService.new(params.require(:phone)).verify_otp(params.require(:otp))

          if result[:success]
            user = User.find_by(phone: normalize_phone(params[:phone]))
            user&.update!(verified: true)
            render_success({ verified: true, message: result[:message] })
          else
            render_error(result[:message], status: :unprocessable_entity)
          end
        end

        # POST /api/v1/auth/send_otp
        def send_otp
          result = ::Auth::OtpService.new(params.require(:phone)).send_otp
          if result[:success]
            render_success({ message: result[:message] })
          else
            render_error(result[:message], status: :unprocessable_entity)
          end
        end

        private

        def signup_params
          params.permit(:username, :email, :phone, :password, :display_name)
        end

        def user_payload(user)
          {
            id:           user.id,
            username:     user.username,
            display_name: user.display_name,
            email:        user.email,
            phone:        user.phone,
            is_guest:     user.is_guest,
            verified:     user.verified,
            coins:        user.coins,
            level:        user.level,
            xp:           user.xp
          }
        end

        def normalize_phone(phone)
          phone.gsub(/\D/, "").then { |p| p.start_with?("91") ? p : "91#{p}" }
        end
      end
    end
  end
end
