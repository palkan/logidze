# frozen_string_literal: true

module Logidze
  module IgnoreLogData
    module Association # :nodoc:
      def target_scope
        super.with_log_data
      end
    end
  end
end
