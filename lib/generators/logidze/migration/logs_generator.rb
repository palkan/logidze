# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Logidze
  module Generators
    module Migration
      class LogsGenerator < Rails::Generators::Base
        include Rails::Generators::Migration

        source_root File.expand_path("templates", __dir__)

        def generate_migration
          migration_template "migration.rb.erb", "db/migrate/create_logidze_data.rb"
        end

        def self.next_migration_number(dir)
          ::ActiveRecord::Generators::Base.next_migration_number(dir)
        end
      end
    end
  end
end
