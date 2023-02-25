# frozen_string_literal: true

module Logidze
  module PostgresHelpers
    def database_version
      @database_version ||=
        ::ActiveRecord::Base.connection.select_value("SELECT current_setting('server_version_num')::int;") / 10000
    end
  end
end
