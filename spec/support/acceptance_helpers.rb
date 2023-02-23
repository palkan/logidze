# frozen_string_literal: true

require "open3"

module Logidze
  module AcceptanceHelpers # :nodoc:
    def successfully(command)
      status, out, err = run_command command, env: {"RAILS_ENV" => "test"}
      expect(status).to be_success, "'#{command}' expected to succeed but failed\nOut: #{out}\nErr: #{err}\n"
    end

    def unsuccessfully(command)
      status, out, err = run_command command, env: {"RAILS_ENV" => "test"}
      expect(status).not_to be_success, "'#{command}' expected to fail but succeed\nOut: #{out}\nErr: #{err}\n"
    end

    def verify_file_contains(path, statement)
      expect(File.readlines(path).grep(/#{statement}/))
        .not_to be_empty, "File #{path} does not contain '#{statement}'"
    end

    def verify_file_not_contain(path, statement)
      expect(File.readlines(path).grep(/#{statement}/))
        .to be_empty, "File #{path} should not contain '#{statement}'"
    end

    def run_command(cmd, env: {}, success: true)
      output, err, status =
        Open3.capture3(
          env,
          cmd
        )

      if ENV["LOG"]
        puts "\n\nCOMMAND:\n#{command}\n\nOUTPUT:\n#{output}\nERROR:\n#{err}\n"
      end

      [status, output, err]
    end

    def suppress_output
      return yield if ENV["LOG"].present?

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

    extend self # rubocop: disable all
  end
end
