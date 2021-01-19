# frozen_string_literal: true

require "logidze"
require "generators/logidze/install/check_pending"

module Logidze
  class Engine < Rails::Engine # :nodoc:
    config.logidze = Logidze

    initializer "extend ActiveRecord with Logidze" do |_app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, Logidze::HasLogidze
      end
    end

    initializer "check Logidze function versions" do |app|
      ActiveSupport.on_load(:active_record) do
        app.config.app_middleware.use Logidze::Generators::CheckPending
      end
    end
  end
end
