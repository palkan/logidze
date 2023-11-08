# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :posts do
      primary_key :id

      column :data, :json
      column :log_data, :jsonb
      column :meta, :jsonb
      Integer :rating
      String :title
      TrueClass :active

      foreign_key :user_id, :users

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
