# frozen_string_literal: true
require 'active_support'

module Logidze
  # Add `has_logidze` method to AR::Base
  module HasLogidze
    extend ActiveSupport::Concern

    module ClassMethods # :nodoc:
      # Include methods to work with history.
      #
      # rubocop:disable Style/PredicateName
      def has_logidze(*_hargs)
        include Logidze::Model
      end
    end
  end
end
