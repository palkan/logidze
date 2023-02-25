# frozen_string_literal: true

require "acceptance_helper"

describe "partition change", :db do
  context "partitioned by age" do
    include_context "cleanup migrations"

    before(:all) do
      skip if database_version < 11

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model partitioned_user --after-trigger"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      PartitionedUser.reset_column_information
    end

    describe "update" do
      let(:partitioned_user) { PartitionedUser.create!(name: "Partition User", age: 5, active: true).reload }

      it "creates a new version like a full snapshot", :aggregate_failures do
        expect(partitioned_user.log_version).to eq 1

        partitioned_user.update!(age: 25)

        expect(partitioned_user.reload.log_version).to eq 2
        expect(partitioned_user.log_data.versions.last.changes)
          .to include("name" => "Partition User", "age" => 25, "active" => true)

        partitioned_user.update!(age: 30)

        expect(partitioned_user.reload.log_version).to eq 3
        expect(partitioned_user.log_data.versions.last.changes)
          .to include("age" => 30)
        expect(partitioned_user.log_data.versions.last.changes.keys)
          .not_to include("tittle", "active")
      end
    end

    describe "timestamp_column is not set" do
      let(:partitioned_user) { PartitionedUser.create!(age: 10, updated_at: Time.at(0)).reload }

      it "uses 'updated_at' column if it exists", :aggregate_failures do
        Timecop.freeze(Time.at(1_000_000)) do
          partitioned_user.update!(age: 20)
        end

        expect(partitioned_user.reload).to use_timestamp(:updated_at)
      end

      it "sets version timestamp to statement_timestamp() if 'updated_at' did not change", :aggregate_failures do
        Timecop.freeze(Time.at(0)) do
          partitioned_user.update!(age: 20)
        end

        expect(partitioned_user.reload).to use_statement_timestamp
      end
    end
  end
end
