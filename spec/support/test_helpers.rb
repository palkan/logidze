# frozen_string_literal: true
module Logidze
  module TestHelpers #:nodoc:
    BASE_TIME = Time.parse("2016-04-12 12:00:00").to_i

    # Returns time in milliseconds for 2016-04-12 12:00:00.
    # @param {Numerid} shift Time shift in seconds
    def time(shift = 0)
      (BASE_TIME + shift) * 1_000
    end

    def ignore_exceptions
      return unless block_given?

      begin
        yield
      rescue StandardError
      end
    end
  end
end
