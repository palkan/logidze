# frozen_string_literal: true

class CreateDetachedOtherUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :detached_other_users do |t|
      t.string :name
      t.integer :age
      t.boolean :active
      t.jsonb :extra
      t.string :settings, array: true
      t.timestamp :time
    end
  end
end
