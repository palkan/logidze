# frozen_string_literal: true

class DetachedPost < ActiveRecord::Base
  attr_accessor :errored

  validate :is_errored

  has_logidze detached: true

  belongs_to :user

  def reload
    self.errored = nil
    super
  end

  def is_errored
    return unless errored
    errors.add(:base, "Errored")
  end
end
