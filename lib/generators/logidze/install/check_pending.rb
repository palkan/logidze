# frozen_string_literal: true

require_relative "function_definitions"

module Logidze
  class PendingMigrationError < StandardError
  end

  module Generators
    class CheckPending
      def initialize(app)
        @app = app
      end

      delegate :connection, to: ActiveRecord::Base

      def call(env)
        notify_or_raise! if Logidze.check_pending_upgrade && needs_migration?

        @app.call(env)
      end

      private

      def notify_or_raise!
        msg = "Logidze needs upgrade. Run `bundle exec rails generate logidze:install --update`"
        raise Logidze::PendingMigrationError, msg if Logidze.raise_on_pending_upgrade

        warn msg
      end

      def needs_migration?
        (library_function_versions - pg_function_versions).any?
      end

      def pg_function_versions
        Logidze::Generators::FunctionDefinitions.from_db.map { |func| [func.name, func.version] }
      end

      def library_function_versions
        Logidze::Generators::FunctionDefinitions.from_fs.map { |func| [func.name, func.version] }
      end
    end
  end
end
