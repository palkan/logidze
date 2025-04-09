# frozen_string_literal: true

require "active_support"

module Logidze
  # Add `has_logidze` method to AR::Base
  module HasLogidze
    extend ActiveSupport::Concern

    module ClassMethods # :nodoc:
      # Include methods to work with history.
      def has_logidze(ignore_log_data: Logidze.ignore_log_data_by_default, detached: Logidze.detached_log_placement?)
        include Logidze::IgnoreLogData
        include Logidze::Model
        if detached && !Logidze.inline_log_placement?
          # Adds needed behavior to models and alters behavior of some methods from +Logidze::Model+ to
          # work with detached table for `log_data`
          include Logidze::Detachable
        end

        @ignore_log_data = ignore_log_data

        self.ignored_columns += ["log_data"] if @ignore_log_data
      end

      def ignores_log_data?
        @ignore_log_data
      end
    end
  end
end
