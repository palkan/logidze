class Article < ActiveRecord::Base
  has_logidze

  belongs_to :user
  has_many :comments
end
