# frozen_string_literal: true

Rails.application.configure do
  config.logger = ENV["LOG"] ? Logger.new($stdout) : nil
end
