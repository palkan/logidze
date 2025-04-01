# frozen_string_literal: true

module Logidze
  module Detachable
    extend ActiveSupport::Concern

    included do
      has_one :logidze_data, as: :loggable, class_name: "::Logidze::LogidzeData", dependent: :destroy, autosave: true

      delegate :log_data, to: :logidze_data, allow_nil: true
    end

    module ClassMethods # :nodoc:
      # Nullify log_data column for a association
      #
      # @return [Integer] number of deleted +Logidze::LogidzeData+ records
      def reset_log_data
        Logidze::LogidzeData.where(loggable_id: ids, loggable_type: name).delete_all
      end

      # Initialize log_data with the current state if it's null
      def create_logidze_snapshot(timestamp: nil, only: nil, except: nil, sql_filter: nil)
        ActiveRecord::Base.connection.execute <<~SQL.squish
          INSERT INTO #{Logidze::LogidzeData.quoted_table_name} (log_data, loggable_type, loggable_id)
          SELECT logidze_snapshot(
              to_jsonb(#{quoted_table_name}),
              #{snapshot_query_args(timestamp: timestamp, only: only, except: except)}
            ),
            '#{name}',
            #{quoted_table_name}.id
          FROM #{quoted_table_name}
          #{sql_filter}
          ON CONFLICT (loggable_type, loggable_id)
          DO UPDATE
          SET log_data = EXCLUDED.log_data;
        SQL
      end

      private

      def initial_scope
        includes(:logidze_data)
      end
    end

    # Loads log_data field from the database, stores to the attributes hash and returns it
    def reload_log_data
      reload_logidze_data.log_data
    end

    # Nullify log_data column for a single record
    def reset_log_data
      tap { logidze_data.delete }.reload_logidze_data
    end

    # Initialize log_data with the current state if it's null for a single record
    def create_logidze_snapshot!(timestamp: nil, only: nil, except: nil)
      id_filter = "WHERE #{self.class.quoted_table_name}.id = #{id}"
      self.class.create_logidze_snapshot(timestamp: timestamp, only: only, except: except, sql_filter: id_filter)

      reload_log_data
    end

    def raw_log_data
      logidze_data&.read_attribute_before_type_cast(:log_data)
    end

    def log_data=(v)
      logidze_data&.assign_attributes(log_data: v) || build_logidze_data(log_data: v)
      v # rubocop:disable Lint/Void
    end

    def dup
      super.tap { _1.logidze_data = logidze_data.dup }
    end

    protected

    # rubocop: disable Lint/ShadowedArgument
    def build_dup(log_entry, requested_ts = log_entry.time, object_at: nil)
      object_at = dup
      object_at.logidze_data = logidze_data.dup
      super
    end
    # rubocop: enable Lint/ShadowedArgument
  end
end
