# frozen_string_literal: true

module Logidze
  module Detachable
    extend ActiveSupport::Concern

    included do
      has_one :logidze_data, as: :loggable, class_name: "Logidze::LogidzeData", dependent: :destroy

      delegate :log_data, to: :logidze_data
    end

    # Loads log_data field from the database, stores to the attributes hash and returns it
    def reload_log_data
      self.log_data = Logidze::LogidzeData.where(loggable: self).first.log_data
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
