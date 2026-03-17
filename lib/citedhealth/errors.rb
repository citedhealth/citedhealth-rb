# frozen_string_literal: true

module CitedHealth
  # General API error.
  class Error < StandardError; end

  # Raised when the server returns HTTP 404.
  class NotFoundError < Error; end

  # Raised when the server returns HTTP 429.
  # Exposes the Retry-After header value when present.
  class RateLimitError < Error
    attr_reader :retry_after

    def initialize(message = "Rate limit exceeded", retry_after: nil)
      @retry_after = retry_after
      super(message)
    end
  end
end
