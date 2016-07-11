class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.integer :age
      t.boolean :active
      t.jsonb :log_data
      t.timestamps null: false
    end
  end
end
