# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "action_controller/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.eager_load = true

    config.logger = ENV["LOG"] ? Logger.new($stdout) : Logger.new(IO::NULL)
    config.active_record.dump_schema_after_migration = false
  end
end
