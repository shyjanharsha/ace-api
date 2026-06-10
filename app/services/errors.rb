module Errors
  class Base         < StandardError; end
  class InvalidToken < Base; end
  class TokenExpired < Base; end
  class Unauthorized < Base; end
  class Forbidden    < Base; end
  class NotFound     < Base; end
  class UnprocessableEntity < Base; end
  class GameError    < Base; end
  class InvalidMove  < GameError; end
  class NotYourTurn  < GameError; end
  class InsufficientCoins < Base; end
  class RoomFull     < Base; end
  class RoomClosed   < Base; end
end
