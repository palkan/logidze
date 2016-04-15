require "logidze/version"

# Logidze provide tools for adding in-table JSON-based audit to DB tables
# and ActiveRecord extensions to work with changes history.
module Logidze
  require 'logidze/model'
  require 'logidze/has_logidze'

  require 'logidze/engine' if defined?(Rails)
end
