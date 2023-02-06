# frozen_string_literal: true

module Logidze
  module PgVersionsHelpers #:nodoc:
    PG_MINIMUM_VERSION = 11
    SKIP_POSTGRES_V11_12_MESSAGE = "Skipped specs for PG 11 version and upper, because current PG VERSION is another".freeze

    def only_for_pg_version_11_and_upper(current_pg_version)
      if current_pg_version < PG_MINIMUM_VERSION
        return skip(SKIP_POSTGRES_V11_12_MESSAGE)
      end

      yield
    end
  end
end
