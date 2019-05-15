# frozen_string_literal: true

module Logidze
  # Contains helpers for handling different PG versions
  module Migration
    # Checks whether pg function `current_setting` support `missing_ok` argument
    # (since 9.6)
    def current_setting_missing_supported?
      ActiveRecord::Base.connection.send(:postgresql_version) >= 90_600
    end

    def current_setting(name)
      if current_setting_missing_supported?
        "current_setting('#{name}', true)"
      else
        "current_setting('#{name}')"
      end
    end
  end
end
