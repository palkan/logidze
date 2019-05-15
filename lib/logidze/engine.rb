# frozen_string_literal: true

require "logidze"

module Logidze
  class Engine < Rails::Engine # :nodoc:
    initializer "extend ActiveRecord with Logidze" do |_app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, Logidze::HasLogidze
      end
    end
  end
end
