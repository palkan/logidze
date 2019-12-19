# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "logidze/version"

Gem::Specification.new do |spec|
  spec.name = "logidze"
  spec.version = Logidze::VERSION
  spec.authors = ["palkan"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "PostgreSQL JSON-based auditing"
  spec.description = "PostgreSQL JSON-based auditing"
  spec.homepage = "http://github.com/palkan/logidze"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.4.0"

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/logidze/issues",
    "changelog_uri" => "https://github.com/palkan/logidze/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/logidze",
    "homepage_uri" => "http://github.com/palkan/logidze",
    "source_code_uri" => "http://github.com/palkan/logidze"
  }

  spec.add_dependency "rails", "6.0.2.1"

  spec.add_development_dependency "ammeter", "~> 1.1.3"
  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "pg", ">= 0.18"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec-rails", ">= 3.4"
  spec.add_development_dependency "rubocop-md", "~> 0.2.0"
  spec.add_development_dependency "standard", "~> 0.1.2"
  spec.add_development_dependency "timecop", "~> 0.8"
end
