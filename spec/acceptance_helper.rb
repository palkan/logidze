# frozen_string_literal: true

require "spec_helper"

require "digest/sha1"

# For faster development, let's not re-create a database for every test run,
# only if Logidze SQL has changed
#
# Heavily inspired by Webpacker: https://github.com/rails/webpacker/blob/master/lib/webpacker/compiler.rb
module ConditionalDatabaseReset
  class << self
    def tmp_path
      @tmp_path ||= Pathname.new(File.join(__dir__, "..", "tmp"))
    end

    def digest_path
      @digest_path ||= tmp_path.join("test_db.digest")
    end

    def watched_files_patterns
      [
        File.join(__dir__, "..", "lib/generators/logidze/install/functions/*.sql"),
        File.join(__dir__, "..", "lib/generators/logidze/install/templates/*")
      ]
    end

    def stale?
      last_digest != watched_files_digest || ENV["FORCE_DB_RESET"]
    end

    def last_digest
      digest_path.read if digest_path.exist?
    rescue Errno::ENOENT, Errno::ENOTDIR
    end

    def watched_files_digest
      @watched_files_digest ||=
        begin
          files = Dir[*watched_files_patterns].reject { |f| File.directory?(f) }
          file_ids = files.sort.map { |f| "#{File.basename(f)}/#{Digest::SHA1.file(f).hexdigest}" }
          file_ids << "/fx:#{USE_FX}"
          Digest::SHA1.hexdigest(file_ids.join("/"))
        end
    end

    def record_digest
      tmp_path.mkpath
      digest_path.write(watched_files_digest)
    end
  end
end

RSpec.configure do |config|
  config.include Logidze::AcceptanceHelpers
  config.include Logidze::PostgresHelpers

  config.around(:each) do |example|
    Dir.chdir("#{File.dirname(__FILE__)}/dummy") do
      example.run
    end
  end

  migrations_to_delete = []

  config.before(:suite) do
    Dir.chdir("#{File.dirname(__FILE__)}/dummy") do
      if ConditionalDatabaseReset.stale?
        start = Time.now

        ActiveRecord::Base.connection_pool.disconnect!

        $stdout.print "⌛️  Creating database and installing Logidze... "

        migrations_to_delete << Dir.glob("db/migrate/*_enable_hstore.rb").first
        migrations_to_delete << Dir.glob("db/migrate/*_logidze_install.rb").first

        # Delete existing migrations
        migrations_to_delete.compact.each { |path| File.delete(path) }

        # Delete fx artefacts
        FileUtils.rm_rf("db/functions") if File.directory?("db/functions")
        FileUtils.rm_rf("db/triggers") if File.directory?("db/triggers")

        Logidze::AcceptanceHelpers.suppress_output do
          system <<-CMD
            rails db:drop db:create db:environment:set RAILS_ENV=test
            rails generate logidze:install
            rails db:migrate
          CMD
        end

        $stdout.puts "Done in #{Time.now - start}s"

        ConditionalDatabaseReset.record_digest

        ActiveRecord::Base.connection_pool.disconnect!
      else
        $stdout.puts "🥬  Database is up-to-date!"
      end
    end
  end
end
