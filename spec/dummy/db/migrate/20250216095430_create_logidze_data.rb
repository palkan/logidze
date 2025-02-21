# frozen_string_literal: true

class CreateLogidzeData < ActiveRecord::Migration[5.0]
  def change
    create_table :logidze_data do |t|
      t.jsonb :log_data
      t.belongs_to :loggable, polymorphic: true, index: {name: "index_logidze_loggable", unique: true}
    end
  end
end
