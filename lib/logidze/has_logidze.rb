# frozen_string_literal: true

require "active_support"

module Logidze
  # Add `has_logidze` method to AR::Base
  module HasLogidze
    extend ActiveSupport::Concern

    module ClassMethods # :nodoc:
      # Include methods to work with history.
      def has_logidze(ignore_log_data: Logidze.ignore_log_data_by_default,
        detached: Logidze.detached_log_placement?,
        track_deletes: Logidze.track_deletes)
        include Logidze::IgnoreLogData
        include Logidze::Model

        detached_mode = detached && !Logidze.inline_log_placement?

        if track_deletes && !detached_mode
          raise ArgumentError,
            "`track_deletes: true` requires detached log placement " \
            "(pass `detached: true` or set `Logidze.log_data_placement = :detached`)"
        end

        if detached_mode
          # Adds needed behavior to models and alters behavior of some methods from +Logidze::Model+ to
          # work with detached table for `log_data`
          include Logidze::Detachable

          logidze_data_options = {
            as: :loggable,
            class_name: "::Logidze::LogidzeData",
            autosave: true
          }
          # When `track_deletes` is enabled we intentionally do NOT use
          # `dependent: :destroy` so the `logidze_data` row survives after the
          # origin record is physically deleted. The DB trigger then appends
          # a deletion version to the retained log.
          logidze_data_options[:dependent] = :destroy unless track_deletes

          has_one :logidze_data, **logidze_data_options
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
