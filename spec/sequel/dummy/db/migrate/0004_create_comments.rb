# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :comments do
      primary_key :id

      column :log_data, :jsonb
      String :content

      foreign_key :article_id, :articles

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
