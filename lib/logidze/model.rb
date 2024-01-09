# frozen_string_literal: true

require "active_support"

module Logidze
  # Extends model with methods to browse history
  module Model
    require "logidze/history/type"

    extend ActiveSupport::Concern

    included do
      attribute :log_data, Logidze::History::Type.new

      delegate :version, to: :log_data, prefix: "log"
    end

    module ClassMethods # :nodoc:
      # Return records reverted to specified time
      def at(time: nil, version: nil)
        all.to_a.filter_map { |record| record.at(time: time, version: version) }
      end

      # Return changes made to records since specified time
      def diff_from(time: nil, version: nil)
        all.map { |record| record.diff_from(time: time, version: version) }
      end

      # Alias for Logidze.without_logging
      def without_logging(&block)
        Logidze.without_logging(&block)
      end

      # rubocop: disable Naming/PredicateName
      def has_logidze?
        true
      end
      # rubocop: enable Naming/PredicateName

      # Nullify log_data column for a association
      def reset_log_data
        without_logging { update_all(log_data: nil) }
      end

      # Initialize log_data with the current state if it's null
      def create_logidze_snapshot(timestamp: nil, only: nil, except: nil)
        args = ["'null'"]

        args[0] = "'#{timestamp}'" if timestamp

        columns = only || except

        if columns
          args[1] = "'{#{columns.join(",")}}'"
          args[2] = only ? "true" : "false"
        end

        without_logging do
          where(log_data: nil).update_all(
            <<~SQL
              log_data = logidze_snapshot(to_jsonb(#{quoted_table_name}), #{args.join(", ")})
            SQL
          )
        end
      end
    end

    # Use this to convert Ruby time to milliseconds
    TIME_FACTOR = 1_000

    attr_accessor :logidze_requested_ts

    # Return a dirty copy of record at specified time
    # If time/version is less then the first version, then return nil.
    # If time/version is greater then the last version, then return self.
    # rubocop: disable Metrics/MethodLength
    def at(time: nil, version: nil)
      return at_version(version) if version

      time = parse_time(time)

      unless log_data
        return Logidze.return_self_if_log_data_is_empty ? self : nil
      end

      return nil unless log_data.exists_ts?(time)

      if log_data.current_ts?(time)
        self.logidze_requested_ts = time
        return self
      end

      log_entry = log_data.find_by_time(time)

      build_dup(log_entry, time)
    end

    def logidze_versions(reverse: false, include_self: false)
      versions_meta = log_data.versions.dup

      if reverse
        versions_meta.reverse!
        versions_meta.shift unless include_self
      else
        versions_meta.pop unless include_self
      end

      Enumerator.new { |yielder| versions_meta.each { yielder << at(version: _1.version) } }
    end

    # rubocop: enable Metrics/MethodLength

    # Revert record to the version at specified time (without saving to DB)
    def at!(time: nil, version: nil)
      return at_version!(version) if version

      raise ArgumentError, "#log_data is empty" unless log_data

      time = parse_time(time)

      return self if log_data.current_ts?(time)
      return false unless log_data.exists_ts?(time)

      version = log_data.find_by_time(time).version

      apply_diff(version, log_data.changes_to(version: version))
    end

    # Return a dirty copy of specified version of record
    def at_version(version)
      return nil unless log_data
      return self if log_data.version == version

      log_entry = log_data.find_by_version(version)
      return nil unless log_entry

      build_dup(log_entry)
    end

    # Revert record to the specified version (without saving to DB)
    def at_version!(version)
      raise ArgumentError, "#log_data is empty" unless log_data

      return self if log_data.version == version
      return false unless log_data.find_by_version(version)

      apply_diff(version, log_data.changes_to(version: version))
    end

    # Return diff object representing changes since specified time.
    #
    # @example
    #
    #   post.diff_from(time: 2.days.ago) # or post.diff_from(version: 2)
    #   #=> { "id" => 1, "changes" => { "title" => { "old" => "Hello!", "new" => "World" } } }
    def diff_from(version: nil, time: nil)
      time = parse_time(time) if time
      changes = log_data&.diff_from(time: time, version: version)&.tap do |v|
        deserialize_changes!(v)
      end || {}

      changes.delete_if { |k, _v| deleted_column?(k) }

      {"id" => id, "changes" => changes}
    end

    # Restore record to the previous version.
    # Return false if no previous version found, otherwise return updated record.
    def undo!(append: Logidze.append_on_undo)
      version = log_data.previous_version
      return false if version.nil?

      switch_to!(version.version, append: append)
    end

    # Restore record to the _future_ version (if `undo!` was applied)
    # Return false if no future version found, otherwise return updated record.
    def redo!
      version = log_data.next_version
      return false if version.nil?

      switch_to!(version.version)
    end

    # Restore record to the specified version.
    # Return false if version is unknown.
    def switch_to!(version, append: Logidze.append_on_undo)
      raise ArgumentError, "#log_data is empty" unless log_data

      return false unless at_version(version)

      if append && version < log_version
        changes = log_data.changes_to(version: version)
        changes.each { |c, v| changes[c] = deserialize_value(c, v) }
        update!(changes)
      else
        at_version!(version)
        self.class.without_logging { save! }
      end
    end

    # rubocop: disable Metrics/MethodLength
    def association(name)
      association = super

      return association unless Logidze.associations_versioning

      should_apply_logidze =
        logidze_past? &&
        association.klass.respond_to?(:has_logidze?) &&
        !association.singleton_class.include?(Logidze::VersionedAssociation)

      return association unless should_apply_logidze

      association.singleton_class.prepend Logidze::VersionedAssociation

      if association.is_a? ActiveRecord::Associations::CollectionAssociation
        association.singleton_class.prepend(
          Logidze::VersionedAssociation::CollectionAssociation
        )
      end

      association
    end
    # rubocop: enable Metrics/MethodLength

    def log_size
      log_data&.size || 0
    end

    # Loads log_data field from the database, stores to the attributes hash and returns it
    def reload_log_data
      self.log_data = self.class.where(self.class.primary_key => id).pluck(:"#{self.class.table_name}.log_data").first
    end

    # Nullify log_data column for a single record
    def reset_log_data
      self.class.without_logging { update_column(:log_data, nil) }
    end

    def create_logidze_snapshot!(**opts)
      self.class.where(self.class.primary_key => id).create_logidze_snapshot(**opts)

      reload_log_data
    end

    protected

    def apply_diff(version, diff)
      diff.each do |k, v|
        apply_column_diff(k, v)
      end

      log_data.version = version
      self
    end

    def apply_column_diff(column, value)
      return if deleted_column?(column) || column == "log_data"

      write_attribute column, deserialize_value(column, value)
    end

    def build_dup(log_entry, requested_ts = log_entry.time)
      object_at = dup
      object_at.apply_diff(log_entry.version, log_data.changes_to(version: log_entry.version))
      object_at.id = id
      object_at.logidze_requested_ts = requested_ts

      object_at
    end

    def deserialize_value(column, value)
      @attributes[column].type.deserialize(value)
    end

    def deleted_column?(column)
      !@attributes.key?(column)
    end

    def deserialize_changes!(diff)
      diff.each do |k, v|
        v["old"] = deserialize_value(k, v["old"])
        v["new"] = deserialize_value(k, v["new"])
      end
    end

    def logidze_past?
      return false unless @logidze_requested_ts

      @logidze_requested_ts < Time.now.to_i * TIME_FACTOR
    end

    def parse_time(ts)
      case ts
      when Numeric
        ts.to_i
      when String
        (Time.parse(ts).to_r * TIME_FACTOR).to_i
      when Date
        (ts.to_time.to_r * TIME_FACTOR).to_i
      when Time
        (ts.to_r * TIME_FACTOR).to_i
      end
    end
  end
end
