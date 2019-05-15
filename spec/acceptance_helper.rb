# frozen_string_literal: true

require "spec_helper"

RSpec.configure do |config|
  config.include Logidze::AcceptanceHelpers

  config.around(:each) do |example|
    Dir.chdir("#{File.dirname(__FILE__)}/dummy") do
      example.run
    end
  end

  config.after(:suite) do
    Dir.chdir("#{File.dirname(__FILE__)}/dummy") do
      ActiveRecord::Base.connection_pool.disconnect!

      Logidze::AcceptanceHelpers.suppress_output do
        system <<-CMD
          rake db:drop db:create db:migrate
        CMD
      end
    end
  end
end
