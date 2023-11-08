# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :users do
      primary_key :id

      column :extra, :jsonb
      column :log_data, :jsonb
      column :settings, "text[]"
      DateTime :time
      Integer :age
      String :name
      TrueClass :active
    end
  end
end
