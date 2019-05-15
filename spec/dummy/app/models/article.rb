# frozen_string_literal: true

class Article < ActiveRecord::Base
  has_logidze

  belongs_to :user, Rails::VERSION::MAJOR >= 5 ? {optional: true} : {}
  has_many :comments
end
