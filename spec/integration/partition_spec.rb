# frozen_string_literal: true

require "acceptance_helper"

describe "partition change imitation", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:model post --after_trigger"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
  end

  describe "update" do
    let(:initial_log_data) { Post.create!(title: "Partition Post", rating: 5, active: true).reload.log_data }

    it "creates a new version like a full snapshot", :aggregate_failures do
      post = Post.create!(title: "Partition Post", active: true, rating: 25, log_data: initial_log_data)

      expect(post.reload.log_version).to eq 2
      expect(post.log_data.versions.last.changes)
        .to include("title" => "Partition Post", "rating" => 25, "active" => true)

      post.update!(rating: 30)

      expect(post.reload.log_version).to eq 3
      expect(post.log_data.versions.last.changes)
        .to include("rating" => 30)
      expect(post.log_data.versions.last.changes.keys)
        .not_to include("title", "active")
    end
  end

  describe "timestamp_column is not set" do
    let(:initial_log_data) { Post.create!(rating: 10, updated_at: Time.at(0)).reload.log_data }

    it "uses 'updated_at' column if it exists", :aggregate_failures do
      post = nil
      Timecop.freeze(Time.at(1_000_000)) do
        post = Post.create!(rating: 20, log_data: initial_log_data)
      end

      expect(post.reload.log_version).to eq 2
      expect(post).to use_timestamp(:updated_at)
    end

    it "sets version timestamp to statement_timestamp() if 'updated_at' did not change", :aggregate_failures do
      post = nil
      Timecop.freeze(Time.at(0)) do
        post = Post.create!(rating: 20, log_data: initial_log_data)
      end

      expect(post.reload.log_version).to eq 2
      expect(post).to use_statement_timestamp
    end
  end
end
