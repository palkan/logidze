# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :post_comments do
      primary_key :id

      String :content

      foreign_key :post_id, :posts

      DateTime :created_at, null: false
      DateTime :updated_at, null: false
    end
  end
end
