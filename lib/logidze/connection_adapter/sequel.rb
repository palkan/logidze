# frozen_string_literal: true

module Logidze
  module ConnectionAdapter
    # Sequel realization to manipulate Logidze database settings and attach meta information
    module Sequel
      include Base
      extend self

      def encode_meta(value)
        quote(::Sequel.object_to_json(value))
      end

      def transaction(&block)
        ::Sequel::Model.db.transaction(&block)
      end

      def execute(sql)
        ::Sequel::Model.db.run(sql)
      end

      def quote(string)
        ::Sequel::Model.db.literal(string)
      end
    end
  end
end
