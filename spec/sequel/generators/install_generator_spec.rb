# frozen_string_literal: true

require "generators/logidze/install/install_generator"

describe Logidze::Generators::InstallGenerator, type: :generator, sequel: true do
  destination File.expand_path("../../../tmp", __dir__)

  let(:base_args) { [] }
  let(:sequel_args) { ["--sequel"] }
  let(:args) { base_args + sequel_args }

  before do
    prepare_destination
  end

  describe "hstore migration" do
    subject { migration_file("db/migrate/enable_hstore.rb") }

    it "creates migration", :aggregate_failures do
      run_generator(args)

      is_expected.to exist
      is_expected.to contain "Sequel.migration"
      is_expected.to contain "up do"
      is_expected.to contain "CREATE EXTENSION IF NOT EXISTS hstore"
      is_expected.to contain "down do"
      is_expected.to contain "DROP EXTENSION IF EXISTS hstore CASCADE"
    end
  end

  describe "trigger migration" do
    subject { migration_file("db/migrate/logidze_install.rb") }

    it "creates migration", :aggregate_failures do
      run_generator(args)

      is_expected.to exist
      is_expected.to contain "Sequel.migration"
      is_expected.to contain "up do"
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_logger()/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_snapshot/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_version/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_filter_keys/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_compact_history/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_capture_exception/i)
      is_expected.to contain "down do"
      is_expected.to contain "DROP FUNCTION IF EXISTS logidze_logger"
      is_expected.to contain "DROP FUNCTION IF EXISTS logidze_snapshot"
      is_expected.to contain "DROP FUNCTION IF EXISTS logidze_version"
      is_expected.to contain "DROP FUNCTION IF EXISTS logidze_filter_keys"
      is_expected.to contain "DROP FUNCTION IF EXISTS logidze_compact_history"
      is_expected.to contain "DROP FUNCTION IF EXISTS logidze_capture_exception"
    end
  end

  context "update migration" do
    let(:version) { Logidze::VERSION.delete(".") }
    let(:base_args) { ["--update"] }

    subject { migration_file("db/migrate/logidze_update_#{version}.rb") }

    it "creates only functions", :aggregate_failures do
      run_generator(args)

      expect(migration_file("db/migrate/enable_hstore.rb")).not_to exist
      expect(migration_file("db/migrate/logidze_install.rb")).not_to exist

      is_expected.to exist
      is_expected.to contain "Sequel.migration"
      is_expected.to contain "up do"
      is_expected.to contain(/Drop legacy functions/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_logger()/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_snapshot/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_version/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_filter_keys/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_compact_history/i)
      is_expected.to contain(/CREATE OR REPLACE FUNCTION logidze_capture_exception/i)
      is_expected.to contain "down do"
    end
  end
end
