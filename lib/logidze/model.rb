# frozen_string_literal: true
require 'active_support'

module Logidze
  # Extends model with methods to browse history
  module Model
    require 'logidze/history/type'

    extend ActiveSupport::Concern

    included do
      attribute :log_data, Logidze::History::Type.new

      delegate :version, :size, to: :log_data, prefix: "log"
    end

    module ClassMethods # :nodoc:
      # Return records reverted to specified time
      def at(ts)
        all.map { |record| record.at(ts) }.compact
      end

      # Return changes made to records since specified time
      def diff_from(ts)
        all.map { |record| record.diff_from(ts) }
      end

      # Alias for Logidze.without_logging
      def without_logging(&block)
        Logidze.without_logging(&block)
      end
    end

    # Use this to convert Ruby time to milliseconds
    TIME_FACTOR = 1_000

    # Return a dirty copy of record at specified time
    # If time is less then the first version, then return nil.
    # If time is greater then the last version, then return self.
    def at(ts)
      ts = parse_time(ts)
      return nil unless log_data.exists_ts?(ts)
      return self if log_data.current_ts?(ts)

      object_at = dup
      object_at.apply_diff(log_data.changes_to(time: ts))
    end

    # Revert record to the version at specified time (without saving to DB)
    def at!(ts)
      ts = parse_time(ts)
      return self if log_data.current_ts?(ts)
      return false unless log_data.exists_ts?(ts)

      apply_diff(log_data.changes_to(time: ts))
    end

    # Return a dirty copy of specified version of record
    def at_version(version)
      return self if log_data.version == version
      return nil unless log_data.find_by_version(version)

      object_at = dup
      object_at.apply_diff(log_data.changes_to(version: version))
    end

    # Revert record to the specified version (without saving to DB)
    def at_version!(version)
      return self if log_data.version == version
      return false unless log_data.find_by_version(version)

      apply_diff(log_data.changes_to(version: version))
    end

    # Return diff object representing changes since specified time.
    #
    # @example
    #
    #   post.diff_from(2.days.ago)
    #   #=> { "id" => 1, "changes" => { "title" => { "old" => "Hello!", "new" => "World" } } }
    def diff_from(ts)
      ts = parse_time(ts)
      { "id" => id, "changes" => log_data.diff_from(time: ts) }
    end

    # Restore record to the previous version.
    # Return false if no previous version found, otherwise return updated record.
    def undo!
      version = log_data.previous_version
      return false if version.nil?
      switch_to!(version.version)
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
    def switch_to!(version)
      return false unless at_version!(version)
      log_data.version = version
      self.class.without_logging { save! }
    end

    protected

    def apply_diff(diff)
      diff.each { |k, v| send("#{k}=", v) }
      self
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
