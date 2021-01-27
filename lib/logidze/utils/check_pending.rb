# frozen_string_literal: true

require_relative "./function_definitions"
require_relative "./pending_migration_error"

module Logidze
  module Utils
    # This Rack middleware is used to verify that all functions are up to date
    class CheckPending
      def initialize(app)
        @app = app
        @needs_check = true
        @mutex = Mutex.new
      end

      delegate :connection, to: ActiveRecord::Base

      def call(env)
        @mutex.synchronize do
          if @needs_check
            notify_or_raise! if needs_migration?
          end
          @needs_check = false
        end

        @app.call(env)
      end

      private

      def notify_or_raise!
        msg = "Logidze needs upgrade. Run `bundle exec rails generate logidze:install --update`"
        case Logidze.on_pending_upgrade
        when :warn
          warn msg
        when :raise
          raise Logidze::Utils::PendingMigrationError, msg
        end
      end

      def needs_migration?
        (library_function_versions - pg_function_versions).any?
      end

      def pg_function_versions
        Logidze::Utils::FunctionDefinitions.from_db.map { |func| [func.name, func.version] }
      end

      def library_function_versions
        @library_function_versions ||= Logidze::Utils::FunctionDefinitions.from_fs.map { |func| [func.name, func.version] }
      end
    end
  end
end
