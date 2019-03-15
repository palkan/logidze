class NotLoggedPostComment < ActiveRecord::Base
  has_logidze ignore_log_data: true

  self.table_name = "post_comments"
end
