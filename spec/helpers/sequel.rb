# frozen_string_literal: true

require File.expand_path("../sequel/dummy/config/environment", __dir__)

Dir["#{File.dirname(__FILE__)}/../support/test_helpers.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.define_derived_metadata(file_path: %r{/spec/sql/}) do |metadata|
    metadata[:type] = :sql
  end

  config.include Logidze::TestHelpers

  config.around(:each, sequel: true) do |example|
    Sequel::Model.db.transaction(rollback: :always, auto_savepoint: true) { example.run }
  end
end
