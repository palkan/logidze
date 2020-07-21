# frozen_string_literal: true

class AddLogidzeToLogidzeUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :logidze_users, :log_data, :jsonb

    reversible do |dir|
      dir.up do
        create_trigger :logidze_on_logidze_users, on: :logidze_users
      end

      dir.down do
        execute "DROP TRIGGER IF EXISTS logidze_on_logidze_users on logidze_users;"
      end
    end
  end
end
