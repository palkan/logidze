# frozen_string_literal: true

class EnableHstore < ActiveRecord::Migration[5.0]
  def change
    enable_extension :hstore
  end
end
