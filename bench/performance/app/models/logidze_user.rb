# frozen_string_literal: true

class LogidzeUser < ApplicationRecord
  has_logidze

  def previous_version
    at(version: log_version - 1)
  end
end
