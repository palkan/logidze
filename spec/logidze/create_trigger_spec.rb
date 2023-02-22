# frozen_string_literal: true

require "acceptance_helper"
require "pg_versions_helper"

RSpec.configure do |c|
  c.include Logidze::SqlHelpers
end

describe "create logidze trigger on table" do
  include_context "cleanup migrations"

  let(:partitioned_table_name) { PartitionedPost.table_name }
  let(:table_name) { Post.table_name }
  let(:trigger_partitioned_name) { "logidze_on_#{partitioned_table_name}" }
  let(:trigger_table_name) { "logidze_on_#{table_name}" }

  let(:fetch_triggers_on_table) do
    lambda do |table_name, trigger_name|
      sql_with_args("
        SELECT array_agg(action_timing)
        FROM information_schema.triggers
        WHERE event_object_table = ? AND trigger_name = ?", table_name, trigger_name
      )
    end
  end

  # Running specs for postgres version 11 and 12, because these versions need AFTER ROW trigger for partitioned tables
  only_for_pg_version_11_12 do
    before(:all) do
      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model partitioned_post --only-trigger --limit 4"
        successfully "rails generate logidze:model post --only-trigger --limit 4"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end
    end

    context "when postgresql 11 and 12 versions" do
      context "when table is partitioned" do
        it "exists only AFTER ROW trigger" do
          result = fetch_triggers_on_table.call(partitioned_table_name, trigger_partitioned_name)

          expect(result).not_to include("BEFORE")
          expect(result).to include("AFTER")
        end
      end

      context "when table is not partitioned" do
        it "exists only BEFORE ROW trigger" do
          result = fetch_triggers_on_table.call(table_name, trigger_table_name)

          expect(result).not_to include("AFTER")
          expect(result).to include("BEFORE")
        end
      end
    end
  end

  # Running specs for postgres versions 13 and above. These versions support BEFORE ROW trigger on partitioned tables
  only_for_pg_version_13_version_and_above do
    before(:all) do
      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model partitioned_post --only-trigger --limit 4"
        successfully "rails generate logidze:model post --only-trigger --limit 4"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end
    end

    context "when postgresql 13 version and above" do
      context "when table is partitioned" do
        it "exists only BEFORE ROW trigger" do
          result = fetch_triggers_on_table.call(partitioned_table_name, trigger_partitioned_name)

          expect(result).not_to include("AFTER")
          expect(result).to include("BEFORE")
        end
      end

      context "when table is not partitioned" do
        it "exists only BEFORE ROW trigger" do
          result = fetch_triggers_on_table.call(table_name, trigger_table_name)

          expect(result).not_to include("AFTER")
          expect(result).to include("BEFORE")
        end
      end
    end
  end
end
