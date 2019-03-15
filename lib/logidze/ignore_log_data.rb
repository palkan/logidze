# frozen_string_literal: true

require "logidze/ignore_log_data/association"

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

    module ClassMethods # :nodoc:
      def self.default_scope
        ignores_log_data? ? super : super.with_log_data
      end
    end

    def association(name)
      association = super

      should_load_log_data =
        attributes["log_data"] &&
        association.klass.respond_to?(:has_logidze?) &&
        !association.singleton_class.include?(Logidze::IgnoreLogData::Association)

      return association unless should_load_log_data

      association.singleton_class.prepend(Logidze::IgnoreLogData::Association)

      association
    end
  end
end
