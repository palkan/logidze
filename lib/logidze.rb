# frozen_string_literal: true

require "logidze/version"

# Logidze provides tools for adding in-table JSON-based audit to DB tables
# and ActiveRecord extensions to work with changes history.
module Logidze
  require "logidze/history"
  require "logidze/model"
  require "logidze/model/time_helper"
  require "logidze/model/active_record"
  require "logidze/model/sequel"
  require "logidze/versioned_association"
  require "logidze/ignore_log_data"
  require "logidze/has_logidze"
  require "logidze/adapter/base"
  require "logidze/adapter/active_record"
  require "logidze/adapter/sequel"

  require "logidze/engine" if defined?(Rails)

  class << self
    # Determines which DB adapter (ActiveRecord or Sequel) Logidze uses by default for manupulations
    attr_accessor :default_adapter
    # Determines if Logidze should append a version to the log after updating an old version
    attr_accessor :append_on_undo
    # Determines whether associations versioning is enabled or not
    attr_accessor :associations_versioning
    # Determines if Logidze should exclude log data from SELECT statements
    attr_accessor :ignore_log_data_by_default
    # Whether #at should return self or nil when log_data is nil
    attr_accessor :return_self_if_log_data_is_empty
    # Determines what Logidze should do when upgrade is needed (:raise | :warn | :ignore)
    attr_reader :on_pending_upgrade

    def on_pending_upgrade=(mode)
      if %i[raise warn ignore].exclude? mode
        raise ArgumentError,
          "Unknown on_pending_upgrade option `#{mode.inspect}`. Expecting :raise, :warn or :ignore"
      end
      @on_pending_upgrade = mode
    end

    ADAPTERS = {active_record: Adapter::ActiveRecord, sequel: Adapter::Sequel}.freeze

    # Access DB adapter for manupulations.
    #
    # @example
    #   Logidze[:active_record].without_logging { Post.update_all(active: true) }
    def [](adapter)
      ADAPTERS.fetch(adapter.to_sym)
    end

    # Temporary disable DB triggers (default adapter).
    #
    # @example
    #   Logidze.without_logging { Post.update_all(active: true) }
    def without_logging(&block)
      self[default_adapter].without_logging(&block)
    end

    # Instruct Logidze to create a full snapshot for the new versions, not a diff (default adapter).
    #
    # @example
    #   Logidze.with_full_snapshot { post.touch }
    def with_full_snapshot(&block)
      self[default_adapter].with_full_snapshot(&block)
    end

    # Store any meta information inside the version (it could be IP address, user agent, etc.)
    # (default adapter).
    #
    # @example
    #   Logidze.with_meta({ip: request.ip}) { post.save! }
    def with_meta(meta, transactional: true, &block)
      self[default_adapter].with_meta(meta, transactional: transactional, &block)
    end

    # Store special meta information about changes' author inside the version (Responsible ID).
    # Usually, you would like to store the `current_user.id` that way
    # (default adapter).
    #
    # @example
    #   Logidze.with_responsible(user.id) { post.save! }
    def with_responsible(responsible_id, transactional: true, &block)
      self[default_adapter].with_responsible(responsible_id, transactional: transactional, &block)
    end
  end

  self.default_adapter = :active_record
  self.append_on_undo = false
  self.associations_versioning = false
  self.ignore_log_data_by_default = false
  self.return_self_if_log_data_is_empty = true
  self.on_pending_upgrade = :ignore
end
