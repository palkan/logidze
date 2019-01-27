# frozen_string_literal: true
require 'active_support'

module Logidze
  # Add `has_logidze` method to AR::Base
  module HasLogidze
    extend ActiveSupport::Concern

    module ClassMethods # :nodoc:
      # Include methods to work with history.
      #
      # rubocop:disable Naming/PredicateName
      def has_logidze(ignore_log_data: nil)
        include Logidze::Model
        include Logidze::IgnoreLogData

        @ignore_log_data = ignore_log_data
      end

      def ignores_log_data?
        if @ignore_log_data.nil? && Logidze.ignore_log_data_by_default
          !Logidze.force_load_log_data
        else
          @ignore_log_data
        end
      end
    end
  end
end
