require "rails/generators"
require "rails/generators/active_record"

module Logidze
  module Generators
    class InstallGenerator < ::Rails::Generators::Base # :nodoc:
      include Rails::Generators::Migration

      source_root File.expand_path('../templates', __FILE__)

      def generate_migration
        migration_template "migration.rb.erb", "db/migrate/logidze_install.rb"
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
