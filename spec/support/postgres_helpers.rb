# frozen_string_literal: true

module Logidze
  module PostgresHelpers
    def database_version
      @database_version ||=
        ::ActiveRecord::Base.connection.execute("SELECT current_setting('server_version_num')::int;").values.first.first / 10000
    end
  end
end
