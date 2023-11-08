# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "action_controller/railtie"
require "sequel"

require "logidze"

module Dummy
  class Application < Rails::Application
    config.load_defaults "6.0"

    config.eager_load = false
  end
end
