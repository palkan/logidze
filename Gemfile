# frozen_string_literal: true
source 'https://rubygems.org'

# Specify your gem's dependencies in logidze.gemspec
gemspec

gem "pry-byebug", platform: :mri

local_gemfile = "#{File.dirname(__FILE__)}/Gemfile.local"

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Lint/Eval
else
  gem 'activerecord', '~> 5.1.1'
end
