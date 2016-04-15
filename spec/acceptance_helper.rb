require "spec_helper"

RSpec.configure do |config|
  config.include Logidze::AcceptanceHelpers

  config.around(:each) do |example|
    Dir.chdir("spec/dummy") do
      example.run
    end
  end

  config.after(:suite) do
    Dir.chdir("spec/dummy") do
      ActiveRecord::Base.connection_pool.disconnect!
      system <<-CMD
        rake db:drop db:create db:migrate
      CMD
    end
  end
end
