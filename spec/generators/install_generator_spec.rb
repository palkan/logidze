# frozen_string_literal: true

require "spec_helper"
require "generators/logidze/install/install_generator"

describe Logidze::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  let(:args) { [] }

  before do
    prepare_destination
    run_generator(args)
  end

  describe "trigger migration" do
    subject { migration_file("db/migrate/logidze_install.rb") }

    it "creates migration", :aggregate_failures do
      is_expected.to exist
      is_expected.to contain(/create or replace function logidze_logger()/i)
      is_expected.to contain(/create or replace function logidze_snapshot/i)
      is_expected.to contain(/create or replace function logidze_exclude_keys/i)
      is_expected.to contain(/create or replace function logidze_compact_history/i)
      is_expected.to contain(/alter database .* set logidze\.disabled/i)
    end
  end

  describe "hstore migration" do
    subject { migration_file("db/migrate/enable_hstore.rb") }

    it "creates migration", :aggregate_failures do
      is_expected.to exist
      is_expected.to contain(/enable_extension :hstore/i)
    end
  end

  context "update migration" do
    let(:version) { Logidze::VERSION.delete(".") }
    let(:args) { ["--update"] }

    subject { migration_file("db/migrate/logidze_update_#{version}.rb") }

    it "creates only functions", :aggregate_failures do
      expect(migration_file("db/migrate/enable_hstore.rb")).not_to exist
      expect(migration_file("db/migrate/logidze_install.rb")).not_to exist

      is_expected.to exist
      is_expected.to contain(/create or replace function logidze_logger()/i)
      is_expected.to contain(/create or replace function logidze_snapshot/i)
      is_expected.to contain(/create or replace function logidze_exclude_keys/i)
      is_expected.to contain(/create or replace function logidze_compact_history/i)
    end
  end
end
