# frozen_string_literal: true

class LogidzeInstall < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        create_function :logidze_logger, version: 1
      end

      dir.down do
        execute "DROP FUNCTION logidze_logger() CASCADE"
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_version, version: 1
      end

      dir.down do
        execute "DROP FUNCTION logidze_version(bigint, jsonb, timestamp with time zone) CASCADE"
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_snapshot, version: 1
      end

      dir.down do
        execute "DROP FUNCTION logidze_snapshot(jsonb, text, text[], boolean) CASCADE"
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_filter_keys, version: 1
      end

      dir.down do
        execute "DROP FUNCTION logidze_filter_keys(jsonb, text[], boolean) CASCADE"
      end
    end

    reversible do |dir|
      dir.up do
        create_function :logidze_compact_history, version: 1
      end

      dir.down do
        execute "DROP FUNCTION logidze_compact_history(jsonb, integer) CASCADE"
      end
    end
  end
end
