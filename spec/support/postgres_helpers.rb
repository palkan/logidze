# frozen_string_literal: true

module Logidze
  module PostgresHelpers #:nodoc:
    def database_version
      @database_version ||=
        ::ActiveRecord::Base.connection.select_value("SELECT current_setting('server_version_num')::int;")
    end

    # server_version_num range
    def skip_database_versions(versions)
      skip("Skip for postgres versions #{versions}") if versions.include? database_version
    end
  end
end
