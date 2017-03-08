# frozen_string_literal: true
module Logidze
  module VersionedAssociation
    def load_target
      target = super

      return target if inversed

      time = owner.logidze_requested_ts

      if target.is_a? Array
        target.map! do |object|
          object unless object.class.has_logidze?

          object.at(time)
        end.compact!
      elsif target.class.has_logidze?
        target.at!(time)
      end

      target
    end

    def stale_target?
      logidze_stale? || super
    end

    def logidze_stale?
      return false if !loaded? || inversed

      unless target.is_a?(Array)
        return owner.logidze_requested_ts != target.logidze_requested_ts
      end

      return false if target.empty?

      owner.logidze_requested_ts != target.first.logidze_requested_ts
    end

    module CollectionAssociation
      def empty?
        reload
        super
      end
    end
  end
end
