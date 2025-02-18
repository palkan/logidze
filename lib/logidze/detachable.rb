# frozen_string_literal: true

module Logidze
  module Detachable
    extend ActiveSupport::Concern

    included do
      has_one :logidze_data, as: :loggable, class_name: "Logidze::LogidzeData", dependent: :destroy

      delegate :log_data, to: :logidze_data
    end

    module ClassMethods # :nodoc:
      # Nullify log_data column for a association
      def reset_log_data
        without_logging { Logidze::LogidzeData.where(loggable_type: name).destroy_all }
      end

      # Initialize log_data with the current state if it's null
      def create_logidze_snapshot(timestamp: nil, only: nil, except: nil)
        args = ["'null'"]

        args[0] = "'#{timestamp}'" if timestamp

        columns = only || except

        if columns
          args[1] = "'{#{columns.join(",")}}'"
          args[2] = only ? "true" : "false"
        end

        query = <<~SQL
          insert into logidze_data (log_data, loggable_type, loggable_id, created_at, updated_at)
          select logidze_snapshot(to_jsonb(#{quoted_table_name}), #{args.join(", ")}), '#{name}', 
                 #{quoted_table_name}.id, current_timestamp, current_timestamp
          from #{quoted_table_name}
          where #{quoted_table_name}.id not in (
            select ld.loggable_id
            from logidze_data ld
            inner join #{quoted_table_name} on ld.loggable_id = #{quoted_table_name}.id 
            and ld.loggable_type = '#{name}'
          );
        SQL

        without_logging { ActiveRecord::Base.connection.execute(query) }
      end
    end

    # Loads log_data field from the database, stores to the attributes hash and returns it
    def reload_log_data
      self.log_data = Logidze::LogidzeData.where(loggable: self).first.log_data
    end

    def log_size
      return 0 if logidze_data.nil?

      log_data&.size || 0
    end

    # Nullify log_data column for a single record
    def reset_log_data
      Logidze::LogidzeData.where(loggable: self).destroy_all
    end

    # TODO: refactor to align with .create_logidze_snapshot
    def create_logidze_snapshot!(timestamp: nil, only: nil, except: nil)
      args = ["'null'"]

      args[0] = "'#{timestamp}'" if timestamp

      columns = only || except

      if columns
        args[1] = "'{#{columns.join(",")}}'"
        args[2] = only ? "true" : "false"
      end

      query = <<~SQL
        insert into logidze_data (log_data, loggable_type, loggable_id, created_at, updated_at)
        select logidze_snapshot(to_jsonb(#{self.class.quoted_table_name}), #{args.join(", ")}), '#{self.class.name}', 
               #{self.class.quoted_table_name}.id, current_timestamp, current_timestamp
        from #{self.class.quoted_table_name}
        where #{self.class.quoted_table_name}.id not in (
          select ld.loggable_id
          from logidze_data ld
          inner join #{self.class.quoted_table_name} on ld.loggable_id = #{self.class.quoted_table_name}.id 
          and ld.loggable_type = '#{self.class.name}'
        )
        and #{self.class.quoted_table_name}.id = #{id};
      SQL

      Logidze.without_logging { ActiveRecord::Base.connection.execute(query) }

      reload_log_data
    end

    # Restore record to the specified version.
    # Return false if version is unknown.
    def switch_to!(version, append: Logidze.append_on_undo)
      raise ArgumentError, "#log_data is empty" unless Logidze::LogidzeData.exists?(loggable: self)

      return false unless at_version(version)

      if append && version < log_version
        changes = log_data.changes_to(version: version)
        changes.each { |c, v| changes[c] = deserialize_value(c, v) }
        update!(changes)
      else
        at_version!(version)
        self.class.without_logging do
          ActiveRecord::Base.transaction do
            save!
            logidze_data.save!
          end
        end
      end
    end

    protected

    def build_dup(log_entry, requested_ts = log_entry.time)
      object_at = dup
      logidze_data_at = logidze_data.dup
      object_at.logidze_data = logidze_data_at
      object_at.apply_diff(log_entry.version, log_data.changes_to(version: log_entry.version))
      object_at.id = id
      object_at.logidze_requested_ts = requested_ts

      object_at
    end
  end
end
