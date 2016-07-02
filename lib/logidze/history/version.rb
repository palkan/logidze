# frozen_string_literal: true
module Logidze
  class History
    # Represents one log item
    class Version
      # Timestamp key
      TS = 'ts'
      # Changes key
      CHANGES = 'c'

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
    end
  end
end
