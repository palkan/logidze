# frozen_string_literal: true

module Logidze
  module Detachable
    extend ActiveSupport::Concern

    included do
      has_one :logidze_data, as: :loggable, class_name: "::Logidze::LogidzeData", dependent: :destroy, autosave: true

      delegate :log_data, :log_data=, to: :logidze_data, allow_nil: true
    end

    module ClassMethods # :nodoc:
      # Nullify log_data column for a association
      #
      # @return [Integer] number of deleted +Logidze::LogidzeData+ records
      def reset_log_data
        Logidze::LogidzeData.where(loggable_id: ids, loggable_type: name).delete_all
      end

      # Initialize log_data with the current state if it's null
      def create_logidze_snapshot(timestamp: nil, only: nil, except: nil)
        ActiveRecord::Base.connection.execute <<~SQL.squish
          INSERT INTO logidze_data (log_data, loggable_type, loggable_id)
          SELECT logidze_snapshot(
              to_jsonb(#{quoted_table_name}),
              #{snapshot_query_args(timestamp: timestamp, only: only, except: except)}
            ),
            '#{name}',
            #{quoted_table_name}.id
          FROM #{quoted_table_name}
          WHERE #{quoted_table_name}.id NOT IN (
            SELECT ld.loggable_id
            FROM logidze_data ld
            INNER JOIN #{quoted_table_name} on ld.loggable_id = #{quoted_table_name}.id
            AND ld.loggable_type = '#{name}'
          );
        SQL
      end

      # Computes args for creating initializing snapshots in +.create_logidze_snapshot+ and +#create_logidze_snapshot!+
      def snapshot_query_args(timestamp: nil, only: nil, except: nil)
        args = ["'null'"]

        args[0] = "'#{timestamp}'" if timestamp

        columns = only || except

        if columns
          args[1] = "'{#{columns.join(",")}}'"
          args[2] = only ? "true" : "false"
        end

        args.join(", ")
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
      ActiveRecord::Base.connection.execute <<~SQL.squish
        INSERT INTO logidze_data (log_data, loggable_type, loggable_id)
        SELECT logidze_snapshot(
            to_jsonb(#{self.class.quoted_table_name}),
            #{self.class.snapshot_query_args(timestamp: timestamp, only: only, except: except)}
          ),
          '#{self.class.name}',
          #{self.class.quoted_table_name}.id
        FROM #{self.class.quoted_table_name}
        WHERE #{self.class.quoted_table_name}.id NOT IN (
          SELECT ld.loggable_id
          FROM logidze_data ld
          INNER JOIN #{self.class.quoted_table_name} on ld.loggable_id = #{self.class.quoted_table_name}.id
          AND ld.loggable_type = '#{self.class.name}'
        )
        AND #{self.class.quoted_table_name}.id = #{id};
      SQL

      reload_log_data
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
