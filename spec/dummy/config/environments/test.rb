# frozen_string_literal: true

Rails.application.configure do
  config.logger = ENV["LOG"] ? Logger.new(STDOUT) : nil
  config.active_record.dump_schema_after_migration = false
end
