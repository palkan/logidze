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
      def has_logidze(ignore_log_data: false)
        include Logidze::Model
        include Logidze::IgnoreLogData if ignore_log_data
      end
    end
  end
end
