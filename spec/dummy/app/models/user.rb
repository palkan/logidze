class User < ActiveRecord::Base
  has_logidze

  delegate :responsible_id, :meta, to: :log_data

  has_many :not_logged_posts

  def whodunnit
    User.find(responsible_id) if responsible_id.present?
  end
end
