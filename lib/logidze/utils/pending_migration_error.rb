# frozen_string_literal: true

require "rails/generators"

module Logidze
  module Utils
    class PendingMigrationError < StandardError
      require "active_record"
      require "active_support/actionable_error"
      include ActiveSupport::ActionableError

      action "Upgrade Logidze" do
        Rails::Generators.invoke("logidze:install", ["--update"])
        ActiveRecord::Tasks::DatabaseTasks.migrate
        if ActiveRecord::Base.dump_schema_after_migration
          ActiveRecord::Tasks::DatabaseTasks.dump_schema(
            ActiveRecord::Base.connection_db_config
          )
        end
      end
    end
  end
end
