# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "action_controller/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

# Conditionally load fx
USE_FX = ENV["USE_FX"] == "true"

require "logidze"
if USE_FX
  require "fx"
  $stdout.puts "🔩 Fx is loaded"
end

unless ActiveRecord::Migration.respond_to?(:[])
  ActiveRecord::Migration.singleton_class.send(:define_method, :[]) { |_| self }
end

module Dummy
  class Application < Rails::Application
    config.eager_load = false
  end
end
