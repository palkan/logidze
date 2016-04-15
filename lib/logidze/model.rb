# frozen_string_literal: true
require 'active_support'

module Logidze
  # Extends model with methods to browse history
  module Model
    extend ActiveSupport::Concern

    module ClassMethods # :nodoc:
      # Return records reverted to specified time
      def at(ts)
        all.map { |record| record.at(ts) }.compact
      end

      # Return changes made to records since specified time
      def diff_from(ts)
        all.map { |record| record.diff_from(ts) }
      end
    end

    # Use this to convert Ruby time to milliseconds
    TIME_FACTOR = 1_000

    # History key
    HISTORY = 'h'
    # Version key
    VERSION = 'v'
    # Timestamp key
    TS = 'ts'
    # Changes key
    CHANGES = 'c'

    # Return a dirty copy of record at specified time
    # If time is less then the first version, then return nil.
    # If time is greater then the last version, then return self.
    def at(ts)
      ts = parse_time(ts)
      return nil unless version_exists?(ts)
      return self if same_version?(ts)

      object_at = dup
      object_at.apply_diff(changes_to(ts))
    end

    # Revert record to the version at specified time (without saving to DB)
    def at!(ts)
      ts = parse_time(ts)
      return self if same_version?(ts) || !version_exists?(ts)

      apply_diff(changes_to(ts))
    end

    # Return diff object representing changes since specified time.
    #
    # @example
    #
    #   post.diff_from(2.days.ago)
    #   #=> { "id" => 1, "changes" => { "title" => { "old" => "Hello!", "new" => "World" } } }
    def diff_from(ts)
      ts = parse_time(ts)

      base = changes_to(ts)
      diff = changes_to(log_history.last.fetch(TS), base)

      changes_hash = {}

      diff.each do |k, v|
        changes_hash[k] = { "old" => base[k], "new" => v } unless v == base[k]
      end

      { "id" => id, "changes" => changes_hash }
    end

    # Restore record to the previous version.
    # Return false if no previous version found, otherwise return updated record.
    def undo!
      version = previous_version
      return false if version.nil?
      switch_to!(version)
    end

    # Restore record to the _future_ version (if `undo!` was applied)
    # Return false if no future version found, otherwise return updated record.
    def redo!
      version = next_version
      return false if version.nil?
      switch_to!(version)
    end

    def switch_to!(version)
      at!(version.fetch(TS))
      log_data[VERSION] = version.fetch(VERSION)
      save!
    end

    def log_history
      log_data.fetch(HISTORY)
    end

    def log_version
      log_data.fetch(VERSION)
    end

    protected

    def apply_diff(diff)
      diff.each { |k, v| send("#{k}=", v) }
      self
    end

    def changes_to(ts, data = {})
      diff = data.dup
      log_history.detect do |v|
        break true if v.fetch(TS) > ts
        diff.merge!(v.fetch(CHANGES))
        false
      end
      diff
    end

    private

    def find_version(version)
      log_history.find { |v| v.fetch(VERSION) == version }
    end

    def current_version
      find_version(log_version)
    end

    def previous_version
      find_version(log_version - 1)
    end

    def next_version
      find_version(log_version + 1)
    end

    def version_exists?(ts)
      log_history.present? && log_history.first.fetch(TS) <= ts
    end

    def same_version?(ts)
      (current_version.fetch(TS) <= ts) &&
        (next_version.nil? || (next_version.fetch(TS) < ts))
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
