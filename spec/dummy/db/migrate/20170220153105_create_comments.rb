# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.text :content
      t.jsonb :log_data
      t.references :article, foreign_key: true

      t.timestamps null: false
    end
  end
end
