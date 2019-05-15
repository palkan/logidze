# frozen_string_literal: true
ENV["RAILS_ENV"] = "test"

require "pry-byebug"
require "ammeter"
require "timecop"

if ENV['COVER']
  require 'simplecov'
  SimpleCov.root File.join(File.dirname(__FILE__), '..')
  SimpleCov.add_filter "/spec/"
  SimpleCov.start
end

require File.expand_path('dummy/config/environment', __dir__)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_excluding(rails5: true) if Rails::VERSION::MAJOR < 5

  config.example_status_persistence_file_path = "tmp/rspec_examples.txt"
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.include Logidze::TestHelpers

  config.before(:each, db: true) do
    ActiveRecord::Base.connection.begin_transaction(joinable: false)
  end

  config.append_after(:each, db: true) do
    ActiveRecord::Base.connection.rollback_transaction
  end
end
