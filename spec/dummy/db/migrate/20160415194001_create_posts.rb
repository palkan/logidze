class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :title
      t.integer :rating
      t.boolean :active
      t.jsonb :meta

      t.timestamps null: false
    end
  end
end
