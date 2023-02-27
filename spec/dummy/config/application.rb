# frozen_string_literal: true

require File.expand_path("../boot", __FILE__)

require "rails"
require "action_controller/railtie"
require "active_record/railtie"
require "sequel"

Bundler.require(*Rails.groups)

# Conditionally load fx
USE_FX = ENV["USE_FX"] == "true"

# Conditionally set table_name_prefix and/or table_name_suffix
TABLE_NAME_PREFIX = ENV["TABLE_NAME_PREFIX"].presence
TABLE_NAME_SUFFIX = ENV["TABLE_NAME_SUFFIX"].presence

require "logidze"
if USE_FX
  require "fx"
  $stdout.puts "🔩 Fx is loaded"
end

module Dummy
  class Application < Rails::Application
    config.load_defaults "6.0"

    config.eager_load = false

    if TABLE_NAME_PREFIX
      $stdout.puts "🔩 Using table_name_prefix = '#{TABLE_NAME_PREFIX}'"
      config.active_record.table_name_prefix = TABLE_NAME_PREFIX
    end

    if TABLE_NAME_SUFFIX
      $stdout.puts "🔩 Using table_name_suffix = '#{TABLE_NAME_SUFFIX}'"
      config.active_record.table_name_suffix = TABLE_NAME_SUFFIX
    end

    Sequel.postgres(extensions: :activerecord_connection)
  end
end
