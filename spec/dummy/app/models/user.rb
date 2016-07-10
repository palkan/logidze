class User < ActiveRecord::Base
  has_logidze responsible: true

  def whodunnit
    id = log_data.responsible_id
    User.find(id) if id.present?
  end
end
