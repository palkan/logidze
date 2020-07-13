# frozen_string_literal: true

require "logidze/version"

# Logidze provides tools for adding in-table JSON-based audit to DB tables
# and ActiveRecord extensions to work with changes history.
module Logidze
  require "ruby-next"
  require "logidze/history"
  require "logidze/model"
  require "logidze/versioned_association"
  require "logidze/ignore_log_data"
  require "logidze/has_logidze"
  require "logidze/meta"

  extend Logidze::Meta

  require "logidze/engine" if defined?(Rails)

  class << self
    # Determines if Logidze should append a version to the log after updating an old version.
    attr_accessor :append_on_undo

    attr_writer :associations_versioning

    def associations_versioning
      @associations_versioning || false
    end

    # Determines if Logidze should exclude log data from SELECT statements
    attr_writer :ignore_log_data_by_default

    def ignore_log_data_by_default
      @ignore_log_data_by_default || false
    end

    # Temporary disable DB triggers.
    #
    # @example
    #   Logidze.without_logging { Post.update_all(active: true) }
    def without_logging
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute "SET LOCAL logidze.disabled TO on;"
        res = yield
        ActiveRecord::Base.connection.execute "SET LOCAL logidze.disabled TO DEFAULT;"
        res
      end
    end
  end
end
