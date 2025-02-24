# frozen_string_literal: true

class CreateDetachedPosts < ActiveRecord::Migration[5.0]
  def change
    create_table :detached_posts do |t|
      t.string :title
      t.integer :rating
      t.boolean :active
      t.jsonb :meta
      t.json :data
      t.references :user

      t.timestamps null: false
    end
  end
end
