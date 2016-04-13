$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rspec'
require 'pry-byebug'
require 'active_record'

require 'pg'
require 'logidze'

ActiveRecord::Base.establish_connection(
  adapter: 'postgresql',
  host: ENV['DB_HOST'] || 'localhost',
  username: ENV['DB_USER'] || 'logidze',
  database: ENV['DB_NAME'] || 'logidze',
  password: ENV['DB_PASSWORD']
)

connection = ActiveRecord::Base.connection

unless connection.extension_enabled?('hstore')
  connection.enable_extension 'hstore'
  connection.commit_db_transaction
end

connection.reconnect!

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
end
