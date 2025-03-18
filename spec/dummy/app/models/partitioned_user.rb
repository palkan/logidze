# frozen_string_literal: true

class PartitionedUser < ActiveRecord::Base
  self.primary_key = "id"

  has_logidze detached: LOGIDZE_DETACHED
end
