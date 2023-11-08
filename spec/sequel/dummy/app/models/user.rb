# frozen_string_literal: true

class User < Sequel::Model
  plugin :logidze

  one_to_many :posts
  one_to_many :not_logged_posts

  delegate :responsible_id, :meta, to: :log_data, allow_nil: true

  def whodunnit
    self.class.with_pk!(responsible_id) if responsible_id.present?
  end
end
