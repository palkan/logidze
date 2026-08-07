# frozen_string_literal: true

class CreateTrashables < ActiveRecord::Migration[6.0]
  def change
    create_table :trashables do |t|
      t.string :name
      t.integer :rating
      t.boolean :active, default: true
      t.timestamps null: false
    end
  end
end
