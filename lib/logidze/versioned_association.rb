# frozen_string_literal: true

# `inversed` attr_accessor has been removed in Rails 5.2.1
# See https://github.com/rails/rails/commit/39e57daffb9ff24726b1e86dfacf76836dd0637b#diff-c47e1c26ae8a3d486119e0cc91f40a30
unless ::ActiveRecord::Associations::Association.instance_methods.include?(:inversed)
  using(Module.new do
    refine ::ActiveRecord::Associations::Association do
      attr_reader :inversed
    end
  end)
end

module Logidze # :nodoc: all
  module VersionedAssociation
    def load_target
      target = super
      return unless target
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
