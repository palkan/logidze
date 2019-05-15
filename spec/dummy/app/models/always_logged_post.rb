# frozen_string_literal: true

class AlwaysLoggedPost < ActiveRecord::Base
  has_logidze ignore_log_data: false

  self.table_name = "posts"
end
