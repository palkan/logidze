class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.integer :rating
      t.boolean :active
      t.jsonb :log_data
      t.references :user, foreign_key: true

      t.timestamps null: false
    end
  end
end
