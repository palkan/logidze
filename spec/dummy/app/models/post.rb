class Post < ActiveRecord::Base
  attr_accessor :errored

  validate :is_errored

  has_logidze

  def reload
    self.errored = nil
    super
  end

  def is_errored
    return unless errored
    errors.add(:base, 'Errored')
  end
end
