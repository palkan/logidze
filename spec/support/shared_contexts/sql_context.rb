# frozen_string_literal: true

# Helpers for SQL functions testing
module Logidze
  module SqlHelpers
    # Perform SQL query and return the results
    def sql(query)
      result = ::ActiveRecord::Base.connection.execute query
      result.values.first&.first
    end

    # Loads the function from the install generator templates
    def declare_function(name)
      path = File.join(__dir__, "../../../lib/generators/logidze/install/functions", "#{name}.sql")
      raise "Unknown function: #{name}" unless File.file?(path)

      sql File.read(path)
    end

    def drop_function(signature)
      sql "DROP FUNCTION #{signature} CASCADE"
    end
  end
end

RSpec.configure do |config|
  config.include Logidze::SqlHelpers, type: :sql
end
