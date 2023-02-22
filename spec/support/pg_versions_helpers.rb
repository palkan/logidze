# frozen_string_literal: true

module Logidze
  module PgVersionsHelpers #:nodoc:
    PG_11_VERSION = 11
    PG_12_VERSION = 12
    PG_11_12_VERSIONS = [PG_11_VERSION, PG_12_VERSION].freeze

    PG_BELOW_11_VERSION_MESSAGE = "Skipping specs, because current PG version is 10 or below"
    PG_NOT_11_12_VERSIONS_MESSAGE = "Skipping specs, because current PG version is not 11 or 12"
    PG_VERSION_BELOW_13 = "Skipping specs, because current PG version is below 13"

    def current_version
      return @current_version if defined?(@current_version)

      @current_version =
        ActiveRecord::Base
         .connection
         .execute("SELECT (substr(current_setting('server_version'), 1, 2)::smallint)")
         .getvalue(0,0)
    end

    def only_for_pg_version_11_and_above
      unless current_pg_version_eq_or_qt_11?
        return skip(PG_BELOW_11_VERSION_MESSAGE)
      end

      yield
    end

    def only_for_pg_version_11_12
      unless current_version.in?(PG_11_12_VERSIONS)
        return skip(PG_NOT_11_12_VERSIONS_MESSAGE)
      end

      yield
    end

    def only_for_pg_version_13_version_and_above
      if current_version <= PG_12_VERSION
        return skip(PG_VERSION_BELOW_13)
      end

      yield
    end

    def current_pg_version_eq_or_qt_11?
      current_version >= PG_11_VERSION
    end
  end
end
