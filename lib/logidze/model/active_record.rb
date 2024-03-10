# frozen_string_literal: true

require "active_support"

module Logidze
  module Model
    extend ActiveSupport::Concern

    # ActiveRecord connection adapter which allows database serialization,
    # model introspection, modifications and duplication
    class ActiveRecord
      attr_accessor :model

      def initialize(model)
        self.model = model
      end

      def mass_reset_log_data
        model.update_all(log_data: nil)
      end

      def mass_create_logidze_snapshot(args)
        model.where(log_data: nil).update_all(
          <<~SQL
            log_data = logidze_snapshot(to_jsonb(#{model.quoted_table_name}), #{args.join(", ")})
          SQL
        )
      end

      def save!
        model.save!
      end

      def update!(changes)
        model.update!(changes)
      end

      def apply_diff(version, diff)
        diff.each do |k, v|
          apply_column_diff(k, v)
        end

        model.log_data.version = version
        model
      end

      def apply_column_diff(column, value)
        return if deleted_column?(column) || %w[id log_data].include?(column)

        model.write_attribute(column, deserialize_value(column, value))
      end

      def deleted_column?(column)
        !model.attributes.key?(column)
      end

      def deserialize_changes!(diff)
        diff.each do |k, v|
          v["old"] = deserialize_value(k, v["old"])
          v["new"] = deserialize_value(k, v["new"])
        end
      end

      def deserialize_value(column, value)
        model.type_for_attribute(column).deserialize(value)
      end

      def build_dup(log_entry, requested_ts = log_entry.time)
        object_at = model.dup
        object_at = self.class.new(object_at).apply_diff(
          log_entry.version, model.log_data.changes_to(version: log_entry.version)
        )
        object_at.id = model.id
        object_at.logidze_requested_ts = requested_ts

        object_at
      end

      def reload_log_data
        model.log_data = model.class.where(
          model.class.primary_key => model.id
        ).pluck(:"#{model.class.table_name}.log_data").first
      end

      def reset_log_data
        model.update_column(:log_data, nil)
      end
    end
  end
end
