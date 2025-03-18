# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "action_controller/railtie"
require "active_record/railtie"

Bundler.require(*Rails.groups)

# Conditionally load fx
USE_FX = ENV["USE_FX"] == "true"

# Patch Logidze to always use after trigger
# (so we can re-use all the specs)
AFTER_TRIGGER = ENV["AFTER_TRIGGER"] == "true"

# Conditionally set table_name_prefix and/or table_name_suffix
TABLE_NAME_PREFIX = ENV["TABLE_NAME_PREFIX"].presence
TABLE_NAME_SUFFIX = ENV["TABLE_NAME_SUFFIX"].presence

require "logidze"
if USE_FX
  require "fx"
  $stdout.puts "🔩 Fx is loaded"
end

if AFTER_TRIGGER
  require "generators/logidze/model/model_generator"

  Logidze::Generators::ModelGenerator.class_eval do
    def after_trigger?
      return options[:after_trigger] unless options[:after_trigger].nil?

      true
    end
  end
end

module Dummy
  class Application < Rails::Application
    config.eager_load = false

    config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"

    if TABLE_NAME_PREFIX
      $stdout.puts "🔩 Using table_name_prefix = '#{TABLE_NAME_PREFIX}'"
      config.active_record.table_name_prefix = TABLE_NAME_PREFIX
    end

    if TABLE_NAME_SUFFIX
      $stdout.puts "🔩 Using table_name_suffix = '#{TABLE_NAME_SUFFIX}'"
      config.active_record.table_name_suffix = TABLE_NAME_SUFFIX
    end
  end
end
