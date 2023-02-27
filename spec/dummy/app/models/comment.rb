# frozen_string_literal: true

class Comment < ActiveRecord::Base
  has_logidze ignore_log_data: false
  belongs_to :article, optional: true
end
