# frozen_string_literal: true

module SequelModel
  class NotLoggedPost < Sequel::Model(:posts)
    plugin :timestamps, update_on_create: true
    plugin :logidze, ignore_log_data: true

    many_to_one :user
  end
end
