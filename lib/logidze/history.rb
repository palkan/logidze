# frozen_string_literal: true

require "active_support/core_ext/module/delegation"

module Logidze
  # Log data wrapper
  class History
    require "logidze/history/version"

    # History key
    HISTORY = "h"
    # Version key
    VERSION = "v"

    attr_reader :data

    delegate :size, to: :versions
    delegate :responsible_id, :meta, to: :current_version

    def initialize(data)
      @data = data
    end

    def versions
      @versions ||= data.fetch(HISTORY).map { |v| Version.new(v) }
    end

    # Returns current version number
    def version
      data.fetch(VERSION)
    end

    # Change current version
    def version=(val)
      data.store(VERSION, val)
    end

    def current_version
      find_by_version(version)
    end

    def previous_version
      find_by_version(version - 1)
    end

    def next_version
      find_by_version(version + 1)
    end

    # Return diff from the initial state to specified time or version.
    # Optional `data` parameter can be used as initial diff state.
    def changes_to(time: nil, version: nil, data: {}, from: 0)
      raise ArgumentError, "Time or version must be specified" if time.nil? && version.nil?

      filter = time.nil? ? method(:version_filter) : method(:time_filter)
      versions.each_with_object(data.dup) do |v, acc|
        next if v.version < from
        break acc if filter.call(v, version, time)

        acc.merge!(v.changes)
      end
    end

    # Return diff object representing changes since specified time or version.
    #
    # @example
    #
    #   diff_from(time: 2.days.ago)
    #   #=> { "id" => 1, "changes" => { "title" => { "old" => "Hello!", "new" => "World" } } }
    # rubocop:disable Metrics/AbcSize
    def diff_from(time: nil, version: nil)
      raise ArgumentError, "Time or version must be specified" if time.nil? && version.nil?

      from_version = version.nil? ? find_by_time(time) : find_by_version(version)
      from_version ||= versions.first

      base = changes_to(version: from_version.version)
      diff = changes_to(version: self.version, data: base, from: from_version.version + 1)

      build_changes(base, diff)
    end
    # rubocop:enable Metrics/AbcSize

    # Return true iff time greater or equal to the first version time
    def exists_ts?(time)
      versions.present? && versions.first.time <= time
    end

    # Return true iff time corresponds to current version
    def current_ts?(time)
      (current_version.time <= time) &&
        (next_version.nil? || (next_version.time < time))
    end

    # Return version by number or nil
    def find_by_version(num)
      versions.find { |v| v.version == num }
    end

    # Return nearest (from the bottom) version to the specified time
    def find_by_time(time)
      versions.reverse_each.find { |v| v.time <= time }
    end

    def dup
      self.class.new(data.deep_dup)
    end

    def ==(other)
      return super unless other.is_a?(self.class)

      data == other.data
    end

    def as_json(options = {})
      data.as_json(options)
    end

    private

    def build_changes(a, b)
      b.each_with_object({}) do |(k, v), acc|
        acc[k] = {"old" => a[k], "new" => v} unless v == a[k]
      end
    end

    def version_filter(item, version, _)
      item.version > version
    end

    def time_filter(item, _, time)
      item.time > time
    end
  end
end
