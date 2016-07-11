class CustomUser < User
  validates :name, presence: true

  def whodunnit
    name = log_data.responsible_id
    User.find_by!(name: name) if name.present?
  end
end
