# frozen_string_literal: true

class Article < ActiveRecord::Base
  has_logidze detached: LOGIDZE_DETACHED

  belongs_to :user, optional: true, touch: :time
  has_many :comments
end
