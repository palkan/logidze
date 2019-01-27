# frozen_string_literal: true

module Logidze
  module IgnoreLogData # :nodoc:
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

        require "logidze/ignore_log_data/default_scope_patch"
        include DefaultScopePatch
      end

      self.ignored_columns += ["log_data"]

      scope :with_log_data, -> { select(column_names + ["log_data"]) }
    end

    class_methods do
      def self.default_scope
        ignores_log_data? ? super : super.with_log_data
      end
    end
  end
end
