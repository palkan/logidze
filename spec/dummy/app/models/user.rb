class User < ActiveRecord::Base
  has_logidze

  delegate :responsible_id, :meta, to: :log_data

  def whodunnit
    User.find(responsible_id) if responsible_id.present?
  end
end
