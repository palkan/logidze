# frozen_string_literal: true

require "logidze"
require "logidze/utils/check_pending"

module Logidze
  class Engine < Rails::Engine # :nodoc:
    config.logidze = Logidze

    initializer "extend ActiveRecord with Logidze" do |_app|
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.send :include, Logidze::HasLogidze
      end
    end

    initializer "check Logidze function versions" do |app|
      if config.logidze.on_pending_upgrade != :ignore
        ActiveSupport.on_load(:active_record) do
          app.config.app_middleware.use Logidze::Utils::CheckPending
        end
      end
    end
  end
end
