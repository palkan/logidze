# frozen_string_literal: true
module Logidze
  module VersionedAssociation
    def load_target
      target = super

      return target if inversed

      time = owner.logidze_requested_ts

      if target.is_a? Array
        target.map! do |object|
          object unless has_logidze? object

          object.at(time)
        end.compact!
      elsif has_logidze? target
        target.at!(time)
      end

      target
    end

    def has_logidze?(object)
      object.class.included_modules.include? Logidze::Model
    end
  end
end
