# frozen_string_literal: true

class DetachedOtherUser < ActiveRecord::Base
  has_logidze detached: true

  delegate :responsible_id, :meta, to: :log_data

  def whodunnit
    User.find(responsible_id) if responsible_id.present?
  end
end
