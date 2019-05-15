# frozen_string_literal: true

class CreatePostComments < ActiveRecord::Migration[5.0]
  def change
    create_table :post_comments do |t|
      t.text :content
      t.references :post, foreign_key: true

      t.timestamps null: false
    end
  end
end
