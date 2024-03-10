# frozen_string_literal: true

class User < ActiveRecord::Base
  has_logidze

  delegate :responsible_id, :meta, to: :log_data, allow_nil: true

  has_many :not_logged_posts

  def whodunnit
    User.find(responsible_id) if responsible_id.present?
  end
end
