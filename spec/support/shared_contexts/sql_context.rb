# frozen_string_literal: true

# Helpers for SQL functions testing
module Logidze
  module SqlHelpers
    # Perform SQL query and return the results
    def sql(query)
      result = ::ActiveRecord::Base.connection.execute query
      result.values.first&.first
    end

    # Perform SQL query with arguments and return the result
    def sql_with_args(query, *args)
      result = ::ActiveRecord::Base.connection.execute(
        ApplicationRecord.sanitize_sql([query, *args])
      )

      result.getvalue(0, 0)
    end
  end
end

RSpec.configure do |config|
  config.include Logidze::SqlHelpers, type: :sql
end
