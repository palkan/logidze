# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users, force: true do |t|
      t.string :email
      t.integer :position
      t.string :name
      t.text :bio
      t.integer :age
      t.json :dump
      t.jsonb :data
      t.timestamps
    end

    create_table :paper_trail_users, force: true do |t|
      t.string :email
      t.integer :position
      t.string :name
      t.text :bio
      t.integer :age
      t.json :dump
      t.jsonb :data
      t.timestamps
    end

    create_table :logidze_users, force: true do |t|
      t.string :email
      t.integer :position
      t.string :name
      t.text :bio
      t.integer :age
      t.json :dump
      t.jsonb :data
      t.timestamps
    end
  end
end
