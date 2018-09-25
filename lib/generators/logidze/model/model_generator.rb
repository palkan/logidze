# rubocop:disable Metrics/BlockLength
# frozen_string_literal: true
require "rails/generators"
require "rails/generators/active_record/migration/migration_generator"

module Logidze
  module Generators
    class ModelGenerator < ::ActiveRecord::Generators::Base # :nodoc:
      source_root File.expand_path('templates', __dir__)

      class_option :limit, type: :numeric, optional: true, desc: "Specify history size limit"

      class_option :debounce_time, type: :numeric, optional: true, desc: "Specify debounce time in which 2 logs will be merged"

      class_option :backfill, type: :boolean, optional: true,
                              desc: "Add query to backfill existing records history"

      class_option :only_trigger, type: :boolean, optional: true,
                                  desc: "Create trigger-only migration"

      class_option :path, type: :string, optional: true, desc: "Specify path to the model file"

      class_option :blacklist, type: :array, optional: true
      class_option :whitelist, type: :array, optional: true

      class_option :timestamp_column, type: :string, optional: true,
                                      desc: "Specify timestamp column"

      class_option :update, type: :boolean, optional: true,
                            desc: "Define whether this is an update migration"

      def generate_migration
        if options[:blacklist] && options[:whitelist]
          warn "Use only one: --whitelist or --blacklist"
          exit(1)
        end
        migration_template "migration.rb.erb", "db/migrate/#{migration_file_name}"
      end

      def inject_logidze_to_model
        return if update?

        indents = "  " * (class_name.scan("::").count + 1)

        inject_into_class(model_file_path, class_name.demodulize, "#{indents}has_logidze\n")
      end

      no_tasks do
        def migration_name
          if update?
            "update_logidze_for_#{plural_table_name}"
          else
            "add_logidze_to_#{plural_table_name}"
          end
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

        def update?
          options[:update]
        end

        def columns_blacklist
          array = if !options[:whitelist]
                    options[:blacklist]
                  else
                    class_name.constantize.column_names - options[:whitelist]
                  end

          format_pgsql_array(array)
        end

        def timestamp_column
          value = options[:timestamp_column] || 'updated_at'
          return if %w(nil null false).include?(value)

          escape_pgsql_string(value)
        end

        def logidze_logger_parameters
          format_pgsql_args(limit, timestamp_column, columns_blacklist, debounce_time)
        end

        def logidze_snapshot_parameters
          format_pgsql_args('to_jsonb(t)', timestamp_column, columns_blacklist)
        end

        def format_pgsql_array(ruby_array)
          return if ruby_array.blank?

          "'{" + ruby_array.join(', ') + "}'"
        end

        def escape_pgsql_string(string)
          return if string.blank?

          "'#{string}'"
        end

        # Convenience method for formatting pg arguments.
        # Some examples:
        # format_pgsql_args('a', 'b', nil) #=> "a, b"
        # format_pgsql_args(nil, '', 'c')  #=> "null, null, c"
        # format_pgsql_args('a', '', [])   #=> "a"
        def format_pgsql_args(*values)
          args = []
          values.reverse_each do |value|
            formatted_value = value.presence || (args.any? && 'null')
            args << formatted_value if formatted_value
          end
          args.compact.reverse.join(', ')
        end
      end

      private

      def model_file_path
        options[:path] || File.join("app", "models", "#{file_path}.rb")
      end
    end
  end
end
