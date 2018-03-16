# frozen_string_literal: true
require "rails/generators"
require "rails/generators/active_record"

module Logidze
  module Generators
    class InstallGenerator < ::Rails::Generators::Base # :nodoc:
      include Rails::Generators::Migration

      source_root File.expand_path('templates', __dir__)

      class_option :update, type: :boolean, optional: true,
                            desc: "Define whether this is an update migration"

      def generate_migration
        migration_template "migration.rb.erb", "db/migrate/#{migration_name}.rb"
      end

      def generate_hstore_migration
        return if update?
        migration_template "hstore.rb.erb", "db/migrate/enable_hstore.rb"
      end

      no_tasks do
        def migration_name
          if update?
            "logidze_update_#{Logidze::VERSION.delete('.')}"
          else
            "logidze_install"
          end
        end

        def migration_class_name
          migration_name.classify
        end

        def update?
          options[:update]
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
