class Comment < ActiveRecord::Base
  has_logidze
  belongs_to :article
end
