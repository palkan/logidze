# frozen_string_literal: true

module Logidze
  module Model
    # Database-aware time helpers
    module TimeHelper
      extend self

      TIME_FACTOR = 1_000

      def logidze_past?(ts)
        return false unless ts

        ts < Time.now.to_i * TIME_FACTOR
      end

      def parse_time(ts)
        case ts
        when Numeric
          ts.to_i
        when String
          (Time.parse(ts).to_r * TIME_FACTOR).to_i
        when Date
          (ts.to_time.to_r * TIME_FACTOR).to_i
        when Time
          (ts.to_r * TIME_FACTOR).to_i
        end
      end
    end
  end
end
