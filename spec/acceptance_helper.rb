# frozen_string_literal: true

require "spec_helper"

RSpec.configure do |config|
  config.include Logidze::AcceptanceHelpers

  config.around(:each) do |example|
    Dir.chdir("#{File.dirname(__FILE__)}/dummy") do
      example.run
    end
  end

  migrations_to_delete = []

  config.before(:suite) do
    Dir.chdir("#{File.dirname(__FILE__)}/dummy") do
      ActiveRecord::Base.connection_pool.disconnect!

      start = Time.now

      $stdout.print "⌛️  Creating database and installing Logidze... "

      Logidze::AcceptanceHelpers.suppress_output do
        system <<-CMD
          rails db:drop db:create db:environment:set RAILS_ENV=test
          rails generate logidze:install
          rails db:migrate
        CMD
      end

      $stdout.puts "Done in #{Time.now - start}s"

      migrations_to_delete << Dir.glob("db/migrate/*_enable_hstore.rb").first
      migrations_to_delete << Dir.glob("db/migrate/*_logidze_install.rb").first

      ActiveRecord::Base.connection_pool.disconnect!

      $stdout.puts ""
    end
  end

  config.after(:suite) do
    Dir.chdir("#{File.dirname(__FILE__)}/dummy") do
      migrations_to_delete.each { |path| File.delete(path) }

      next unless USE_FX

      FileUtils.rm_rf("db/functions") if File.directory?("db/functions")
      FileUtils.rm_rf("db/triggers") if File.directory?("db/triggers")
    end
  end
end
