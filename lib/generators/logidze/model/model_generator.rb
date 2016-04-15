require "rails/generators"
require "rails/generators/active_record/migration/migration_generator"

module Logidze
  module Generators
    class ModelGenerator < ::ActiveRecord::Generators::Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)

      def generate_migration
        migration_template "migration.rb.erb", "db/migrate/#{migration_file_name}"
      end

      def inject_logidze_to_model
        indents = "  " * (class_name.scan("::").count + 1)

        inject_into_class(File.join("app", "models", "#{file_path}.rb"), class_name.demodulize, "#{indents}has_logidze\n")
      end

      def migration_name
        "add_logidze_to_#{plural_table_name}"
      end

      def migration_file_name
        "#{migration_name}.rb"
      end

      def migration_class_name
        migration_name.camelize
      end
    end
  end
end
