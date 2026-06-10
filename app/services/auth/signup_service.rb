module Auth
  class SignupService
    attr_reader :errors

    def initialize(params)
      @params = params
      @errors = []
    end

    def call
      validate_params!
      check_duplicates!

      user = User.new(
        username:     @params[:username],
        display_name: @params[:display_name] || @params[:username],
        phone:        @params[:phone].presence,
        email:        @params[:email].presence,
        password:     @params[:password],
        is_guest:     false,
        verified:     false
      )

      unless user.save
        @errors = user.errors.full_messages
        return nil
      end

      # Deduct starting coins (set in migration default, just return user)
      user
    end

    def success?
      @errors.empty?
    end

    private

    def validate_params!
      @errors << "Username is required"  if @params[:username].blank?
      @errors << "Password is required"  if @params[:password].blank?
      @errors << "Password too short (min 6 chars)" if @params[:password].present? && @params[:password].length < 6
      @errors << "Phone or email required" if @params[:phone].blank? && @params[:email].blank?
      raise Errors::UnprocessableEntity, @errors.join(", ") if @errors.any?
    end

    def check_duplicates!
      if @params[:phone].present? && User.exists?(phone: @params[:phone])
        raise Errors::UnprocessableEntity, "Phone number already registered"
      end
      if @params[:email].present? && User.exists?(email: @params[:email])
        raise Errors::UnprocessableEntity, "Email already registered"
      end
      if User.exists?(username: @params[:username])
        raise Errors::UnprocessableEntity, "Username already taken"
      end
    end
  end
end
