# frozen_string_literal: true

module Logidze
  module ConnectionAdapter
    # ActiveRecord realization to manipulate Logidze database settings and attach meta information
    module ActiveRecord
      include Base
      extend self

      def transaction(&block)
        ::ActiveRecord::Base.transaction(&block)
      end

      def execute(sql)
        ::ActiveRecord::Base.connection.execute(sql)
      end

      def quote(string)
        ::ActiveRecord::Base.connection.quote(string)
      end
    end
  end
end
