module Auth
  class GuestService
    def call
      username = "Guest_#{SecureRandom.alphanumeric(6)}"

      user = User.create!(
        username:     username,
        display_name: username,
        is_guest:     true,
        verified:     false,
        coins:        ENV.fetch("GUEST_STARTING_COINS", 100).to_i
      )

      tokens = Auth::JwtService.issue_token_pair(user)
      { user: user, tokens: tokens }
    end
  end
end
