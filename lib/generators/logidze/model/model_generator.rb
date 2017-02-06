# frozen_string_literal: true
require "rails/generators"
require "rails/generators/active_record/migration/migration_generator"

module Logidze
  module Generators
    class ModelGenerator < ::ActiveRecord::Generators::Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)

      class_option :limit, type: :numeric, optional: true, desc: "Specify history size limit"

      class_option :backfill, type: :boolean, optional: true,
                              desc: "Add query to backfill existing records history"

      class_option :only_trigger, type: :boolean, optional: true,
                                  desc: "Create trigger-only migration"

      class_option :path, type: :string, optional: true, desc: "Specify path to the model file"

      class_option :blacklist, type: :array, optional: true
      class_option :whitelist, type: :array, optional: true

      def generate_migration
        if options[:blacklist] && options[:whitelist]
          $stderr.puts "Use only one: --whitelist or --blacklist"
          exit(1)
        end
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

        def limit
          options[:limit]
        end

        def backfill?
          options[:backfill]
        end

        def only_trigger?
          options[:only_trigger]
        end

        def columns_blacklist
          array = if !options[:whitelist]
                    options[:blacklist]
                  else
                    class_name.constantize.column_names - options[:whitelist]
                  end

          array || []
        end

        def logidze_logger_parameters
          if limit.nil? && columns_blacklist.empty?
            ''
          elsif !limit.nil? && columns_blacklist.empty?
            limit
          elsif !limit.nil? && !columns_blacklist.empty?
            "#{limit}, #{format_pgsql_array(columns_blacklist)}"
          elsif limit.nil? && !columns_blacklist.empty?
            "null, #{format_pgsql_array(columns_blacklist)}"
          end
        end

        def logidze_snapshot_parameters
          return 'to_jsonb(t)' if columns_blacklist.empty?

          "to_jsonb(t), #{format_pgsql_array(columns_blacklist)}"
        end

        def format_pgsql_array(ruby_array)
          "'{" + ruby_array.join(', ') + "}'"
        end
      end

      private

      def model_file_path
        options[:path] || File.join("app", "models", "#{file_path}.rb")
      end
    end
  end
end
