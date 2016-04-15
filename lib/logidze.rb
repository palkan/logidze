require "logidze/version"

# Logidze provide tools for adding in-table JSON-based audit to DB tables
# and ActiveRecord extensions to work with changes history.
module Logidze
  require 'logidze/model'
  require 'logidze/has_logidze'

  require 'logidze/engine' if defined?(Rails)

  def self.without_logging
  	ActiveRecord::Base.connection.execute "SET session_replication_role = replica;"
  	res = yield
  	ActiveRecord::Base.connection.execute "SET session_replication_role = DEFAULT;"
  	res
  end
end
