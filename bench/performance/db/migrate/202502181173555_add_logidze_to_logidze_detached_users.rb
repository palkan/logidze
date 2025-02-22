# frozen_string_literal: true

class AddLogidzeToLogidzeDetachedUsers < ActiveRecord::Migration[5.0]
  def change
    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_logidze_detached_users, on: :logidze_detached_users
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER IF EXISTS "logidze_on_logidze_detached_users" on "logidze_detached_users";
        SQL
      end
    end
  end
end
