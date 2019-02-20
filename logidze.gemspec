# frozen_string_literal: true
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'logidze/version'

Gem::Specification.new do |spec|
  spec.name          = "logidze"
  spec.version       = Logidze::VERSION
  spec.authors       = ["palkan"]
  spec.email         = ["dementiev.vm@gmail.com"]

  spec.summary       = "PostgreSQL JSON-based auditing"
  spec.description   = "PostgreSQL JSON-based auditing"
  spec.homepage      = "http://github.com/palkan/logidze"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 4.2"

  spec.add_development_dependency "ammeter", "~> 1.1.3"
  spec.add_development_dependency "bundler", "~> 1"
  spec.add_development_dependency "database_cleaner", "~> 1.5"
  spec.add_development_dependency "pg", "~>0.18"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec-rails", ">= 3.4"
  spec.add_development_dependency "rubocop", "~> 0.65.0"
  spec.add_development_dependency "rubocop-md", "~> 0.2.0"
  spec.add_development_dependency "simplecov", ">= 0.3.8"
  spec.add_development_dependency "timecop", "~> 0.8"
end
