# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

begin
  require "debug" unless ENV["CI"] == "true"
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

if ENV["SPEC_TASK"] || ENV["SPEC_ACCEPTANCE_TASK"]
  require File.expand_path("helpers/active_record", __dir__)
end

if ENV["SPEC_SEQUEL_TASK"]
  require File.expand_path("helpers/sequel", __dir__)
end
