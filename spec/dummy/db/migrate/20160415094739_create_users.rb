class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :name
      t.integer :age
      t.boolean :active
      t.jsonb :log_data
      t.timestamp :time
    end
  end
end
