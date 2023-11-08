# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :articles do
      primary_key :id

      column :log_data, :jsonb
      Integer :rating
      String :title
      TrueClass :active

      foreign_key :user_id, :users

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
