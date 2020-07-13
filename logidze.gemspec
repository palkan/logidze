# frozen_string_literal: true

require_relative "lib/logidze/version"

Gem::Specification.new do |spec|
  spec.name = "logidze"
  spec.version = Logidze::VERSION
  spec.authors = ["palkan"]
  spec.email = ["dementiev.vm@gmail.com"]

  spec.summary = "PostgreSQL JSONB-based model changes tracking"
  spec.description = "PostgreSQL JSONB-based model changes tracking"
  spec.homepage = "http://github.com/palkan/logidze"
  spec.license = "MIT"

  spec.files = Dir.glob("lib/**/*") + %w[README.md LICENSE.txt CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5.0"

  spec.metadata = {
    "bug_tracker_uri" => "http://github.com/palkan/logidze/issues",
    "changelog_uri" => "https://github.com/palkan/logidze/blob/master/CHANGELOG.md",
    "documentation_uri" => "http://github.com/palkan/logidze",
    "homepage_uri" => "http://github.com/palkan/logidze",
    "source_code_uri" => "http://github.com/palkan/logidze"
  }

  spec.add_dependency "rails", ">= 5.0"

  spec.add_development_dependency "ammeter", "~> 1.1.3"
  spec.add_development_dependency "bundler", ">= 1.10"
  spec.add_development_dependency "fx", "~> 0.5"
  spec.add_development_dependency "pg", ">= 0.18"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "rspec-rails", ">= 3.4"
  spec.add_development_dependency "timecop", "~> 0.8"
end
