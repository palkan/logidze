# frozen_string_literal: true

class Post < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :logidze

  many_to_one :user
end
