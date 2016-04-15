require "bundler"
require "pry-byebug"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

ENV["RAILS_ENV"] = "test"

RSpec.configure do |config|
  config.include Logidze::AcceptanceHelpers

  config.around(:each) do |example|
    Dir.chdir("spec/dummy") do
      example.run
    end
  end

  config.after(:suite) do
    Dir.chdir("spec/dummy") do
      system <<-CMD
        rake db:drop db:create db:migrate
      CMD
    end
  end
end
