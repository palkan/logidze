# frozen_string_literal: true

class Trashable < ActiveRecord::Base
  has_logidze detached: true, track_deletes: true
end
