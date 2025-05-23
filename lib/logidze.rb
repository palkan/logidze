# frozen_string_literal: true

require "logidze/version"

# Logidze provides tools for adding in-table JSON-based audit to DB tables
# and ActiveRecord extensions to work with changes history.
module Logidze
  require "logidze/history"
  require "logidze/model"
  require "logidze/versioned_association"
  require "logidze/ignore_log_data"
  require "logidze/has_logidze"
  require "logidze/meta"
  require "logidze/detachable"

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
    # Determines if triggers are sorted by related table id or by name
    attr_accessor :sort_triggers_by_name
    # Determines what Logidze should do when upgrade is needed (:raise | :warn | :ignore)
    attr_reader :on_pending_upgrade
    # Determines where to store +log_data+:
    # - +:inline+ - force Logidze to store it in the origin table in the +log_data+ column
    # - +:detached+ - force Logidze to  store it in the +logidze_data+ table in the +log_data+ column
    #
    # By default we do not set +log_data_placement+ value and rely on `has_logidze` macros
    attr_accessor :log_data_placement

    # Temporary disable DB triggers.
    #
    # @example
    #   Logidze.without_logging { Post.update_all(active: true) }
    def without_logging
      with_logidze_setting("logidze.disabled", "on") { yield }
    end

    # Instruct Logidze to create a full snapshot for the new versions, not a diff
    #
    # @example
    #   Logidze.with_full_snapshot { post.touch }
    def with_full_snapshot
      with_logidze_setting("logidze.full_snapshot", "on") { yield }
    end

    def on_pending_upgrade=(mode)
      if %i[raise warn ignore].exclude? mode
        raise ArgumentError, "Unknown on_pending_upgrade option `#{mode.inspect}`. Expecting :raise, :warn or :ignore"
      end
      @on_pending_upgrade = mode
    end

    def detached_log_placement?
      @log_data_placement == :detached
    end

    def inline_log_placement?
      @log_data_placement == :inline
    end

    private

    def with_logidze_setting(name, value)
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute "SET LOCAL #{name} TO #{value};"
        res = yield
        ActiveRecord::Base.connection.execute "SET LOCAL #{name} TO DEFAULT;"
        res
      end
    end
  end

  self.append_on_undo = false
  self.associations_versioning = false
  self.ignore_log_data_by_default = false
  self.return_self_if_log_data_is_empty = true
  self.on_pending_upgrade = :ignore
  self.sort_triggers_by_name = false
  self.log_data_placement = nil
end
