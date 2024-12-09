# frozen_string_literal: true

require "spec_helper"
require "generators/logidze/install/install_generator"

describe Logidze::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  let(:use_fx_args) { USE_FX ? [] : ["--fx"] }
  let(:fx_args) { USE_FX ? ["--no-fx"] : [] }

  let(:base_args) { [] }
  let(:args) { base_args + fx_args }
  let(:ar_version) { "6.0" }

  before do
    prepare_destination
    allow(ActiveRecord::Migration).to receive(:current_version).and_return(ar_version)
  end

  describe "trigger migration" do
    subject { migration_file("db/migrate/logidze_install.rb") }

    it "creates migration", :aggregate_failures do
      run_generator(args)

      is_expected.to be_a_file
      is_expected.to contain "ActiveRecord::Migration[#{ar_version}]"
      is_expected.to contain(/create or replace function logidze_logger()/i)
      is_expected.to contain(/create or replace function logidze_logger_after()/i)
      is_expected.to contain(/create or replace function logidze_snapshot/i)
      is_expected.to contain(/create or replace function logidze_filter_keys/i)
      is_expected.to contain(/create or replace function logidze_compact_history/i)
      is_expected.to contain(/create or replace function logidze_capture_exception/i)
    end

    context "when using fx" do
      let(:fx_args) { use_fx_args }

      it "creates migration", :aggregate_failures do
        run_generator(args)

        is_expected.to be_a_file
        is_expected.to contain "ActiveRecord::Migration[#{ar_version}]"
        is_expected.to contain("create_function :logidze_logger, version: 4")
        is_expected.to contain("create_function :logidze_logger_after, version: 4")
        is_expected.to contain("create_function :logidze_snapshot, version: 3")
        is_expected.to contain("create_function :logidze_version, version: 2")
        is_expected.to contain("create_function :logidze_filter_keys, version: 1")
        is_expected.to contain("create_function :logidze_compact_history, version: 1")
        is_expected.to contain("create_function :logidze_capture_exception, version: 1")

        is_expected.to contain("DROP FUNCTION IF EXISTS logidze_logger")
        is_expected.to contain("DROP FUNCTION IF EXISTS logidze_logger_after")
        is_expected.to contain("DROP FUNCTION IF EXISTS logidze_snapshot")
        is_expected.to contain("DROP FUNCTION IF EXISTS logidze_version")
        is_expected.to contain("DROP FUNCTION IF EXISTS logidze_filter_keys")
        is_expected.to contain("DROP FUNCTION IF EXISTS logidze_compact_history")
        is_expected.to contain("DROP FUNCTION IF EXISTS logidze_capture_exception")
      end

      it "creates function files" do
        run_generator(args)

        is_expected.to be_a_file
        %w[
          logidze_logger_v04.sql
          logidze_logger_after_v04.sql
          logidze_version_v02.sql
          logidze_filter_keys_v01.sql
          logidze_snapshot_v03.sql
          logidze_compact_history_v01.sql
          logidze_capture_exception_v01.sql
        ].each do |path|
          expect(file("db/functions/#{path}")).to be_a_file
        end
      end
    end
  end

  describe "hstore migration" do
    subject { migration_file("db/migrate/enable_hstore.rb") }

    it "creates migration", :aggregate_failures do
      run_generator(args)

      is_expected.to be_a_file
      is_expected.to contain "ActiveRecord::Migration[#{ar_version}]"
      is_expected.to contain(/enable_extension :hstore/i)
    end
  end

  context "update migration" do
    let(:version) { Logidze::VERSION.delete(".") }
    let(:base_args) { ["--update"] }

    subject { migration_file("db/migrate/logidze_update_#{version}.rb") }

    it "creates only functions", :aggregate_failures do
      run_generator(args)

      expect(migration_file("db/migrate/enable_hstore.rb")).not_to be_a_file
      expect(migration_file("db/migrate/logidze_install.rb")).not_to be_a_file

      is_expected.to be_a_file
      is_expected.to contain(/create or replace function logidze_logger()/i)
      is_expected.to contain(/create or replace function logidze_logger_after()/i)
      is_expected.to contain(/create or replace function logidze_snapshot/i)
      is_expected.to contain(/create or replace function logidze_version/i)
      is_expected.to contain(/create or replace function logidze_filter_keys/i)
      is_expected.to contain(/create or replace function logidze_compact_history/i)
      is_expected.to contain(/create or replace function logidze_capture_exception/i)
    end

    context "when using fx" do
      let(:fx_args) { use_fx_args }

      let(:existing) do
        %w[
          logidze_version_v03.sql
          logidze_snapshot_v4.sql
          logidze_filter_keys_v01.sql
          logidze_compact_history_v05.sql
          logidze_logger_v7.sql
          logidze_logger_after_v7.sql
        ]
      end

      before do
        FileUtils.mkdir_p(file("db/functions"))
        existing.each do |path|
          File.write(file("db/functions/#{path}"), "")
        end
      end

      after do
        existing.each do |path|
          File.delete(file("db/functions/#{path}"))
        end

        FileUtils.rm_r(file("db/functions"))
      end

      it "creates migration", :aggregate_failures do
        run_generator(args)

        is_expected.to be_a_file
        is_expected.to contain("update_function :logidze_version, version: 2, revert_to_version: 3")
        is_expected.to contain("update_function :logidze_snapshot, version: 3, revert_to_version: 4")
        is_expected.not_to contain("update_function :logidze_filter_keys")
        is_expected.to contain("update_function :logidze_compact_history, version: 1, revert_to_version: 5")
        is_expected.to contain("update_function :logidze_logger, version: 4, revert_to_version: 7")
        is_expected.to contain("update_function :logidze_logger_after, version: 4, revert_to_version: 7")
        is_expected.to contain("create_function :logidze_capture_exception")
      end

      it "creates function files" do
        run_generator(args)

        is_expected.to be_a_file
        %w[
          logidze_logger_v04.sql
          logidze_logger_after_v04.sql
          logidze_version_v02.sql
          logidze_snapshot_v03.sql
          logidze_compact_history_v01.sql
          logidze_capture_exception_v01.sql
        ].each do |path|
          expect(file("db/functions/#{path}")).to be_a_file
        end
      end
    end
  end
end
