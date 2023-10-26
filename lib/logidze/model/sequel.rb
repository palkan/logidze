# frozen_string_literal: true

module Logidze
  module Model
    # Sequel database adapter which allows database serialization,
    # model introspection, modifications and duplication
    class Sequel
      attr_accessor :model

      def initialize(model)
        self.model = model
      end

      def mass_reset_log_data
        model.update(log_data: nil)
      end

      def mass_create_logidze_snapshot(args)
        model.where(log_data: nil).update(::Sequel.lit(
          <<~SQL
            log_data = logidze_snapshot(to_jsonb(#{model.first_source}), #{args.join(", ")})
          SQL
        ))
      end

      def save!
        model.save.present?
      end

      def update!(changes)
        model.update(changes).present?
      end

      def apply_diff(version, diff)
        diff.each do |k, v|
          apply_column_diff(k, v)
        end

        model.log_data.version = version
        model.set(log_data: model.log_data)
        model
      end

      def apply_column_diff(column, value)
        return if deleted_column?(column) || %w[id log_data].include?(column)

        model.set(column => deserialize_value(column, value))
      end

      def deleted_column?(column)
        !model.to_hash.key?(column.to_sym)
      end

      def deserialize_changes!(diff)
        diff.each do |k, v|
          v["old"] = deserialize_value(k, v["old"])
          v["new"] = deserialize_value(k, v["new"])
        end
      end

      # rubocop:disable Style/RescueModifier
      def deserialize_value(column, value)
        type = model.db_schema.dig(column.to_sym, :db_type)

        manually_deserialized_value =
          if type == "jsonb" || type == "json"
            ::ActiveSupport::JSON.decode(value) rescue nil
          elsif type&.end_with?("[]") && defined?(PG::TextDecoder::Array)
            PG::TextDecoder::Array.new.decode(value)
          else
            value
          end

        model.send(:typecast_value, column.to_sym, manually_deserialized_value)
      end
      # rubocop:enable Style/RescueModifier

      def build_dup(log_entry, requested_ts = log_entry.time)
        object_at = clowne_copier
        object_at = self.class.new(object_at).apply_diff(
          log_entry.version, model.log_data.changes_to(version: log_entry.version)
        )
        object_at.id = model.id
        object_at.logidze_requested_ts = requested_ts

        object_at
      end

      def clowne_copier
        nullify_attrs = [:create_timestamp_field, :update_timestamp_field].map do |timestamp|
          model.class.instance_variable_get("@#{timestamp}")
        end + [:id]

        dup_hash = model.dup.to_hash.tap do |hash|
          nullify_attrs.each { |field| hash.delete(field) }
        end

        model.class.new(dup_hash)
      end

      def reload_log_data
        model.log_data = model.this.get(:log_data)
        model.log_data
      end

      def reset_log_data
        model.update(log_data: nil)
      end
    end
  end
end
