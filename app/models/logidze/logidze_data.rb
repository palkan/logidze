# frozen_string_literal: true

module Logidze
  class LogidzeData < ::ApplicationRecord
    attribute :log_data, Logidze::History::Type.new

    belongs_to :loggable, polymorphic: true
  end
end
