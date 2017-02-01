class Comment < ActiveRecord::Base
  has_logidze
  belongs_to :post
end
