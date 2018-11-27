# frozen_string_literal: true

module Logidze
  # Add `has_logidze` method to AR::Base
  module IgnoreLogData
    extend ActiveSupport::Concern

    included do
      if Rails::VERSION::MAJOR == 4
        require "logidze/ignore_log_data/ignored_columns"
      else
        if Rails::VERSION::MAJOR == 5
          require "logidze/ignore_log_data/cast_attribute_patch"
          include CastAttributePatch
        end

        require "logidze/ignore_log_data/missing_attribute_patch"
        include MissingAttributePatch
      end

      self.ignored_columns += ["log_data"]
    end

    module ClassMethods # :nodoc:
      def with_log_data
        select(column_names + ["log_data"])
      end
    end

    def log_data!
      attributes["log_data"] ||= self.class.where(id: id).pluck(:log_data).first
    end
  end
end
