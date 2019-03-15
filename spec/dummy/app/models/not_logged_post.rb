class NotLoggedPost < ActiveRecord::Base
  has_logidze ignore_log_data: true

  self.table_name = "posts"

  belongs_to :user
  has_many :comments, class_name: "NotLoggedPostComment", foreign_key: :post_id
end
