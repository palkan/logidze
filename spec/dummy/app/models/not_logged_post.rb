# frozen_string_literal: true

class NotLoggedPost < ActiveRecord::Base
  has_logidze ignore_log_data: true

  self.table_name = "#{table_name_prefix}posts#{table_name_suffix}"

  belongs_to :user
  has_many :comments, class_name: "NotLoggedPostComment", foreign_key: :post_id

  class WithDefaultScope < self
    default_scope { joins(:user) }
  end
end
