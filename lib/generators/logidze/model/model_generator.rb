# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record/migration/migration_generator"
require_relative "../inject_sql"
require_relative "../fx_helper"

module Logidze
  module Generators
    class ModelGenerator < ::ActiveRecord::Generators::Base # :nodoc:
      include InjectSql
      include FxHelper

      source_root File.expand_path("templates", __dir__)
      source_paths << File.expand_path("triggers", __dir__)

      class_option :limit, type: :numeric, optional: true, desc: "Specify history size limit"

      class_option :debounce_time, type: :numeric, optional: true,
        desc: "Specify debounce time in millisecond"

      class_option :backfill, type: :boolean, optional: true,
        desc: "Add query to backfill existing records history"

      class_option :only_trigger, type: :boolean, optional: true,
        desc: "Create trigger-only migration"

      class_option :path, type: :string, optional: true, desc: "Specify path to the model file"

      class_option :except, type: :array, optional: true
      class_option :only, type: :array, optional: true

      class_option :timestamp_column, type: :string, optional: true,
        desc: "Specify timestamp column"

      class_option :name, type: :string, optional: true, desc: "Migration name"

      class_option :update, type: :boolean, optional: true,
        desc: "Define whether this is an update migration"

      class_option :after_trigger, type: :boolean, optional: true, desc: "Use after trigger"

      def generate_migration
        if options[:except] && options[:only]
          warn "Use only one: --only or --except"
          exit(1)
        end
        migration_template "migration.rb.erb", "db/migrate/#{migration_name}.rb"
      end

      def generate_fx_trigger
        return unless fx?

        template_name = after_trigger? ? "logidze_after.sql" : "logidze.sql"

        template template_name, "db/triggers/logidze_on_#{table_name}_v#{next_version.to_s.rjust(2, "0")}.sql"
      end

      def inject_logidze_to_model
        return if update?

        indents = "  " * (class_name.scan("::").count + 1)

        inject_into_class(model_file_path, class_name.demodulize, "#{indents}has_logidze\n")
      end

      no_tasks do
        def migration_name
          return options[:name] if options[:name].present?

          if update?
            "update_logidze_for_#{plural_table_name}"
          else
            "add_logidze_to_#{plural_table_name}"
          end
        end

        def full_table_name
          config = ActiveRecord::Base
          "#{config.table_name_prefix}#{table_name}#{config.table_name_suffix}"
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

        def after_trigger?
          options[:after_trigger]
        end

        def filtered_columns
          format_pgsql_array(options[:only] || options[:except])
        end

        def include_columns
          return unless options[:only] || options[:except]
          options[:only].present?
        end

        def timestamp_column
          value = options[:timestamp_column] || "updated_at"
          return if %w[nil null false].include?(value)

          escape_pgsql_string(value)
        end

        def debounce_time
          options[:debounce_time]
        end

        def previous_version
          @previous_version ||= all_triggers.filter_map { |path| Regexp.last_match[1].to_i if path =~ %r{logidze_on_#{table_name}_v(\d+).sql} }.max
        end

        def next_version
          previous_version&.next || 1
        end

        def all_triggers
          @all_triggers ||=
            begin
              res = nil
              in_root do
                res = if File.directory?("db/triggers")
                  Dir.entries("db/triggers")
                else
                  []
                end
              end
              res
            end
        end

        def logidze_logger_parameters
          format_pgsql_args(limit, timestamp_column, filtered_columns, include_columns, debounce_time)
        end

        def logidze_snapshot_parameters
          format_pgsql_args("to_jsonb(t)", timestamp_column, filtered_columns, include_columns)
        end

        def format_pgsql_array(ruby_array)
          return if ruby_array.blank?

          "'{" + ruby_array.join(", ") + "}'"
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
            formatted_value = value.presence || (args.any? && "null")
            args << formatted_value if formatted_value
          end
          args.compact.reverse.join(", ")
        end
      end

      private

      def model_file_path
        options[:path] || File.join("app", "models", "#{file_path}.rb")
      end
    end
  end
end
