# frozen_string_literal: true

module SequelModel
  class CustomUser < Sequel::Model(:users)
    plugin :logidze

    one_to_many :posts
    one_to_many :not_logged_posts

    delegate :responsible_id, :meta, to: :log_data, allow_nil: true

    def whodunnit
      self.class.with_pk!(responsible_id) if responsible_id.present?
    end
  end
end
