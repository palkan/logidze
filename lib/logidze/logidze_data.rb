# frozen_string_literal: true

module Logidze
  class LogidzeData < ActiveRecord::Base
    attribute :log_data, Logidze::History::Type.new

    belongs_to :loggable, polymorphic: true
  end
end
