# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "action_controller/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

require "logidze"

unless ActiveRecord::Migration.respond_to?(:[])
  ActiveRecord::Migration.singleton_class.send(:define_method, :[]) { |_| self }
end

module Dummy
  class Application < Rails::Application
    config.eager_load = false
  end
end
