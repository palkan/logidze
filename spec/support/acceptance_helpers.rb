# frozen_string_literal: true
module Logidze
  module AcceptanceHelpers #:nodoc:
    def successfully(command)
      expect(suppress_output { system("RAILS_ENV=test #{command}") })
        .to eq(true), "'#{command}' was unsuccessful"
    end

    def unsuccessfully(command)
      expect(suppress_output { system("RAILS_ENV=test #{command}") })
        .to eq(false), "'#{command}' was successful"
    end

    def verify_file_contains(path, statement)
      expect(File.readlines(path).grep(/#{statement}/))
        .not_to be_empty, "File #{path} does not contain '#{statement}'"
    end

    def verify_file_not_contain(path, statement)
      expect(File.readlines(path).grep(/#{statement}/))
        .to be_empty, "File #{path} should not contain '#{statement}'"
    end

    def suppress_output
      return yield if ENV['LOG'].present?
      retval = nil
      begin
        original_stderr = $stderr.clone
        original_stdout = $stdout.clone
        $stderr.reopen(IO::NULL)
        $stdout.reopen(IO::NULL)
        retval = yield
      ensure
        $stdout.reopen(original_stdout)
        $stderr.reopen(original_stderr)
      end

      retval
    end

    extend self
  end
end
