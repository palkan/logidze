# frozen_string_literal: true

class CreateLogidzeData < ActiveRecord::Migration[5.0]
  def change
    create_table :logidze_data do |t|
      t.jsonb :log_data
      t.belongs_to :loggable, polymorphic: true, index: false

      t.timestamps

      t.index %w[loggable_type loggable_id], name: "index_logidze_loggable"
    end
  end
end
