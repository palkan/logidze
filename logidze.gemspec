# coding: utf-8
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

  spec.add_dependency "rails", "~> 4.2.6"

  spec.add_development_dependency "pg", "~>0.18"
  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "database_cleaner", "~> 1.5"
  spec.add_development_dependency "simplecov", ">= 0.3.8"
  spec.add_development_dependency "ammeter", "~> 1.1.3"
end
