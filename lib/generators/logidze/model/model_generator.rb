# frozen_string_literal: true
require "rails/generators"
require "rails/generators/active_record/migration/migration_generator"

module Logidze
  module Generators
    class ModelGenerator < ::ActiveRecord::Generators::Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)

      class_option :limit, type: :numeric, optional: true, desc: "Specify history size limit"

      def generate_migration
        migration_template "migration.rb.erb", "db/migrate/#{migration_file_name}"
      end

      def inject_logidze_to_model
        indents = "  " * (class_name.scan("::").count + 1)

        inject_into_class(model_file_path, class_name.demodulize, "#{indents}has_logidze\n")
      end

      no_tasks do
        def migration_name
          "add_logidze_to_#{plural_table_name}"
        end

        def migration_file_name
          "#{migration_name}.rb"
        end

        def migration_class_name
          migration_name.camelize
        end

        def limit
          options[:limit]
        end
      end

      private

      def model_file_path
        File.join("app", "models", "#{file_path}.rb")
      end
    end
  end
end
