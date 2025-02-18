# frozen_string_literal: true

class LogidzeDetachedUser < ApplicationRecord
  has_logidze detached: true
end
