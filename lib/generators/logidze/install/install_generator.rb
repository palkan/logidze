# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"
require_relative "../inject_sql"

using RubyNext

module Logidze
  module Generators
    class InstallGenerator < ::Rails::Generators::Base # :nodoc:
      include Rails::Generators::Migration
      include InjectSql

      class FuncDef < Struct.new(:name, :version, :signature); end

      source_root File.expand_path("templates", __dir__)
      source_paths << File.expand_path("functions", __dir__)

      class_option :fx, type: :boolean, optional: true,
                        desc: "Define whether to use fx gem functionality"
      class_option :update, type: :boolean, optional: true,
                            desc: "Define whether this is an update migration"

      def generate_migration
        migration_template = fx? ? "migration_fx.rb.erb" : "migration.rb.erb"
        migration_template migration_template, "db/migrate/#{migration_name}.rb"
      end

      def generate_hstore_migration
        return if update?

        migration_template "hstore.rb.erb", "db/migrate/enable_hstore.rb"
      end

      def generate_fx_functions
        return unless fx?

        function_definitions.each do |fdef|
          next if fdef.version == previous_version_for(fdef.name)

          template "#{fdef.name}.sql", "db/functions/#{fdef.name}_v#{fdef.version.to_s.rjust(2, "0")}.sql"
        end
      end

      no_tasks do
        def migration_name
          if update?
            "logidze_update_#{Logidze::VERSION.delete(".")}"
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

        def fx?
          options[:fx] || (options[:fx] != false && defined?(::Fx::SchemaDumper))
        end

        def previous_version_for(name)
          all_functions.filter_map { |path| Regexp.last_match[1].to_i if path =~ %r{#{name}_v(\d+).sql} }.max
        end

        def all_functions
          @all_functions ||=
            begin
              res = nil
              in_root do
                res = if File.directory?("db/functions")
                  Dir.entries("db/functions")
                else
                  []
                end
              end
              res
            end
        end

        def function_definitions
          @function_definitions ||=
            begin
              Dir.glob(File.join(__dir__, "functions", "*.sql")).map do |path|
                name = path.match(/([^\/]+)\.sql/)[1]

                file = File.open(path)
                header = file.readline

                version = header.match(/version:\s+(\d+)/)[1].to_i
                parameters = file.readline.match(/CREATE OR REPLACE FUNCTION\s+[\w_]+\((.*)\)/)[1]
                signature = parameters.split(/\s*,\s*/).map { |param| param.split(/\s+/, 2).last.sub(/\s+DEFAULT .*$/, "") }.join(", ")

                FuncDef.new(name, version, signature)
              end
            end
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
