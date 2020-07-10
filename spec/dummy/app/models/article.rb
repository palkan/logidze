# frozen_string_literal: true

class Article < ActiveRecord::Base
  has_logidze

  belongs_to :user, optional: true
  has_many :comments
end
