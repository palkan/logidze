# frozen_string_literal: true

class AddLogidzeDetachedLoggerFunction < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        create_function :logidze_detached_logger, version: 1
      end

      dir.down do
        execute "DROP FUNCTION logidze_detached_logger() CASCADE"
      end
    end
  end
end
