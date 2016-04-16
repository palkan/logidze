# frozen_string_literal: true
module Logidze
  # Log data coder
  class History
    # History key
    HISTORY = 'h'
    # Version key
    VERSION = 'v'

    # Represents one log item
    class Version
      # Timestamp key
      TS = 'ts'
      # Changes key
      CHANGES = 'c'

      attr_reader :data

      def initialize(data)
        @data = data
      end

      def version
        data.fetch(VERSION)
      end

      def changes
        data.fetch(CHANGES)
      end

      def time
        data.fetch(TS)
      end
    end

    def self.dump(object)
      ActiveSupport::JSON.encode(object)
    end

    def self.load(json)
      new(json) unless json.nil?
    end

    attr_reader :data

    delegate :size, to: :versions

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
      find_version(version)
    end

    def previous_version
      find_version(version - 1)
    end

    def next_version
      find_version(version + 1)
    end

    # Return diff from the initial state to specified time or version.
    # Optional `data` paramater can be used as initial diff state.
    def changes_to(time: nil, version: nil, data: {}, from: 0)
      raise "Time or version must be specified" if time.nil? && version.nil?
      diff = data.dup
      filter = time.nil? ? versions_filter(:version, version) : versions_filter(:time, time)
      versions.detect do |v|
        next false if v.version < from
        break true if filter.call(v)
        diff.merge!(v.changes)
        false
      end
      diff
    end

    # Return diff object representing changes since specified time or version.
    #
    # @example
    #
    #   diff_from(time: 2.days.ago)
    #   #=> { "id" => 1, "changes" => { "title" => { "old" => "Hello!", "new" => "World" } } }
    def diff_from(time: nil, version: nil)
      raise "Time or version must be specified" if time.nil? && version.nil?

      from_version = version.nil? ? find_by_time(time) : find_version(version)
      from_version ||= versions.first

      base = changes_to(version: from_version.version)
      diff = changes_to(version: self.version, data: base, from: from_version.version + 1)

      build_changes(base, diff)
    end

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
    def find_version(num)
      versions.find { |v| v.version == num }
    end

    # Return nearest (from the bottom) version to the specified time
    def find_by_time(time)
      versions.reverse.find { |v| v.time <= time }
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
      changes_hash = {}

      b.each do |k, v|
        changes_hash[k] = { "old" => a[k], "new" => v } unless v == a[k]
      end

      changes_hash
    end

    def versions_filter(field, val)
      ->(v) { v.send(field) > val }
    end
  end
end
