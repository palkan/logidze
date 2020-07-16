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
    # Determines whether associations versioning is enabled or not
    attr_accessor :associations_versioning
    # Determines if Logidze should exclude log data from SELECT statements
    attr_accessor :ignore_log_data_by_default
    # Whether #at should return self or nil when log_data is nil
    attr_accessor :return_self_if_log_data_is_empty

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

  self.append_on_undo = false
  self.associations_versioning = false
  self.ignore_log_data_by_default = false
  self.return_self_if_log_data_is_empty = true
end
