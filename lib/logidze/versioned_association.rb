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
  end
end
