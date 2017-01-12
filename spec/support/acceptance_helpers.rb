# frozen_string_literal: true
module Logidze
  module AcceptanceHelpers #:nodoc:
    def successfully(command)
      expect(system("RAILS_ENV=test #{command}"))
        .to eq(true), "'#{command}' was unsuccessful"
    end

    def unsuccessfully(command)
      expect(system("RAILS_ENV=test #{command}")).
        to eq(false), "'#{command}' was successful"
    end

    def verify_file_contains(path, statement)
      expect(File.readlines(path).grep(/#{statement}/))
        .not_to be_empty, "File #{path} does not contain '#{statement}'"
    end

    def verify_file_not_contain(path, statement)
      expect(File.readlines(path).grep(/#{statement}/))
        .to be_empty, "File #{path} should not contain '#{statement}'"
    end
  end
end
