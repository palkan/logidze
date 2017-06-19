class CreatePosts < ActiveRecord::Migration[5.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.integer :rating
      t.boolean :active

      t.timestamps null: false
    end
  end
end
