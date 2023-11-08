# frozen_string_literal: true

Sequel.connect(
  adapter: :postgresql,
  url: ENV["DATABASE_URL"],
  max_connections: 5,
  database: "logidze_test"
)

Sequel.extension :migration
Sequel::Migrator.run(
  Sequel::Model.db,
  File.expand_path("../../db/migrate", __dir__),
  use_transactions: true
)
