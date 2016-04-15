ENV["RAILS_ENV"] = "test"

require "pry-byebug"
require "ammeter"

require File.expand_path("../dummy/config/environment", __FILE__)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
end
