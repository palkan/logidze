# frozen_string_literal: true

RSpec::Matchers.define :be_a_file do |expected|
  match do |file_path|
    File.exist?(file_path)
  end
end
