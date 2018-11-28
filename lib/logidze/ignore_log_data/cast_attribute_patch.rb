# frozen_string_literal: true

module Logidze
  module IgnoreLogData
    # Fixes unexpected behavior (see more https://github.com/rails/rails/pull/34528):
    # instead of using a type passed to `attribute` call, ignored column uses
    # a type coming from the DB (in this case `.log_data` would return a plain hash
    # instead of `Logidze::History`)
    module CastAttributePatch
      def log_data
        return attributes["log_data"] if attributes["log_data"].is_a?(Logidze::History)

        self.log_data = Logidze::History::Type.new.cast_value(super)
      end
    end
  end
end
