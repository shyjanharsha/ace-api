module Auth
  # MSG91 OTP Service
  # Docs: https://docs.msg91.com/reference/send-otp
  class OtpService
    BASE_URL    = "https://control.msg91.com/api/v5/otp".freeze
    VERIFY_URL  = "https://control.msg91.com/api/v5/otp/verify".freeze
    RESEND_URL  = "https://control.msg91.com/api/v5/otp/retry".freeze

    def initialize(phone)
      @phone       = normalize_phone(phone)
      @auth_key    = ENV.fetch("MSG91_AUTH_KEY")
      @template_id = ENV.fetch("MSG91_TEMPLATE_ID")
      @otp_expiry  = ENV.fetch("MSG91_OTP_EXPIRY_MINUTES", "10").to_i
    end

    # Send OTP to phone number
    # Returns { success: true/false, message: "..." }
    def send_otp
      response = connection.post(BASE_URL) do |req|
        req.params = {
          template_id: @template_id,
          mobile:      @phone,
          authkey:     @auth_key,
          expiry:      @otp_expiry
        }
      end

      body = JSON.parse(response.body) rescue {}

      if response.success? && body["type"] == "success"
        { success: true, message: "OTP sent successfully" }
      else
        { success: false, message: body["message"] || "Failed to send OTP" }
      end
    end

    # Verify OTP
    def verify_otp(otp)
      response = connection.get(VERIFY_URL) do |req|
        req.params = {
          authkey: @auth_key,
          mobile:  @phone,
          otp:     otp
        }
      end

      body = JSON.parse(response.body) rescue {}

      if response.success? && body["type"] == "success"
        { success: true, message: "OTP verified" }
      else
        { success: false, message: body["message"] || "Invalid or expired OTP" }
      end
    end

    # Resend OTP
    def resend_otp(type: "text")
      response = connection.get(RESEND_URL) do |req|
        req.params = {
          authkey:  @auth_key,
          mobile:   @phone,
          retrytype: type
        }
      end

      body = JSON.parse(response.body) rescue {}
      response.success? && body["type"] == "success"
    end

    private

    def normalize_phone(phone)
      # Remove spaces, dashes; add country code if needed
      phone.gsub(/\D/, "").then { |p| p.start_with?("91") ? p : "91#{p}" }
    end

    def connection
      @connection ||= Faraday.new do |f|
        f.headers["Content-Type"] = "application/json"
        f.adapter Faraday.default_adapter
      end
    end
  end
end
