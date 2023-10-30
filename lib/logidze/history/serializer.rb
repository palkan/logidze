# frozen_string_literal: true

module Logidze
  class History
    # Sequel serializer for converting JSONB to and from Logidze's History
    module Serializer
      extend self

      SEQUEL_PG_JSON_HASH = %w[Sequel::Postgres::JSONBHash Sequel::Postgres::JSONHash]

      # rubocop:disable Style/RescueModifier
      def deserialize(value)
        case value
        when String
          decoded = ::Sequel.parse_json(value) rescue nil
          History.new(decoded) if decoded.present?
        when Hash, *hashlike
          History.new(value)
        when History
          value
        end
      end
      # rubocop:enable Style/RescueModifier

      def serialize(value)
        case value
        when Hash, *hashlike, History
          ::Sequel.object_to_json(value)
        else
          value
        end
      end

      private

      def hashlike
        SEQUEL_PG_JSON_HASH.map(&:safe_constantize).compact
      end
    end
  end
end
