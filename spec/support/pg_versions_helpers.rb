# frozen_string_literal: true

module Logidze
  module PgVersionsHelpers #:nodoc:
    PG_11_12_VERSIONS = [11, 12].freeze
    PG_10_VERSION = 10

    SKIP_POSTGRES_V11_12_MESSAGE = "Skipped specs for PG 11 and 12 versions, because current PG VERSION is another".freeze
    SKIP_POSTGRES_V10_MESSAGE = "Skipped specs for PG 10 version, because current PG VERSION is another".freeze

    def only_for_pg_version_11_12(current_pg_versions)
      if PG_11_12_VERSIONS.include?(current_pg_versions)
        return skip(SKIP_POSTGRES_V11_12_MESSAGE)
      end

      yield
    end

    def only_for_pg_version_10(current_pg_versions)
      if PG_10_VERSION.include?(current_pg_versions)
        return skip(SKIP_POSTGRES_V10_MESSAGE)
      end

      yield
    end
  end
end
