# frozen_string_literal: true

require "active_model/type"

module Logidze
  class History
    # Type for converting JSONB to and from History
    class Type < ActiveModel::Type::Value
      def type
        :jsonb
      end

      # rubocop:disable Style/RescueModifier
      def cast_value(value)
        case value
        when String
          decoded = ::ActiveSupport::JSON.decode(value) rescue nil
          History.new(decoded) if decoded.present?
        when Hash
          History.new(value)
        when History
          value
        end
      end
      # rubocop:enable Style/RescueModifier

      def serialize(value)
        case value
        when Hash, History
          ::ActiveSupport::JSON.encode(value)
        else
          super
        end
      end

      def changed_in_place?(raw_old_value, new_value)
        cast_value(raw_old_value) != new_value
      end
    end
  end
end
