# frozen_string_literal: true

module Logidze
  class History
    # Represents one log item
    class Version
      # Timestamp key
      TS = "ts"
      # Changes key
      CHANGES = "c"
      # Responsible ID
      RESPONSIBLE = "r"
      # Meta Responsible ID
      META_RESPONSIBLE = "_r"
      # Meta key
      META = "m"

      attr_reader :data

      def initialize(data)
        @data = data
      end

      def version
        data.fetch(VERSION)
      end

      def changes
        data.fetch(CHANGES)
      end

      def time
        data.fetch(TS)
      end

      def responsible_id
        meta && meta[META_RESPONSIBLE] || data[RESPONSIBLE]
      end

      def meta
        data[META]
      end
    end
  end
end
