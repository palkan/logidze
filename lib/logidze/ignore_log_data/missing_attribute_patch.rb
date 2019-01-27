# frozen_string_literal: true

module Logidze
  module IgnoreLogData
    # Rails attribute API defines attributes in a way, that it returns nil
    # when data has not been loaded from the DB. We want it to imitate the behavior
    # from Rails 4 - raise ActiveModel::MissingAttributeError
    module MissingAttributePatch
      def log_data
        if self.class.ignores_log_data? && attributes["log_data"].nil?
          raise ActiveModel::MissingAttributeError
        end

        super
      end
    end
  end
end
