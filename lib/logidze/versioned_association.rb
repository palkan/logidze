# frozen_string_literal: true
module Logidze # :nodoc: all
  module VersionedAssociation
    # rubocop: disable Metrics/MethodLength, Metrics/AbcSize
    def load_target
      target = super

      return target if inversed

      time = owner.logidze_requested_ts

      if target.is_a? Array
        target.map! do |object|
          object.at(time: time)
        end.compact!
      else
        target.at!(time: time)
      end

      target
    end

    def stale_target?
      logidze_stale? || super
    end

    def logidze_stale?
      return false if !loaded? || inversed

      return owner.logidze_requested_ts != target.logidze_requested_ts unless target.is_a?(Array)

      return false if target.empty?

      target.any? do |object|
        owner.logidze_requested_ts != object.logidze_requested_ts
      end
    end

    module CollectionAssociation
      def ids_reader
        reload unless loaded?
        super
      end

      def empty?
        reload unless loaded?
        super
      end
    end
  end
end
