# frozen_string_literal: true

require "acceptance_helper"

shared_context "trigger_debounce_context" do |generator_arg|
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:model post #{generator_arg} --debounce_time=5000"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
  end

  it "does not merge the logs outside debounce_time" do
    post = nil
    Timecop.freeze(Time.at(1_000_000)) do
      post = Post.create!(title: "Triggers", rating: 10)
    end
    Timecop.freeze(Time.at(1_000_100)) do
      post.update!(rating: 100)
    end
    expect(post.reload.log_version).to eq 2
    expect(post.log_size).to eq 2
    expect(post.log_data.versions.last.changes)
      .to_not include("title" => "Triggers")
  end

  it "merges the logs within debounce_time" do
    post = nil
    Timecop.freeze(Time.at(1_000_000)) do
      post = Post.create!(title: "Triggers", rating: 10)
    end
    Timecop.freeze(Time.at(1_000_001)) do
      post.update!(rating: 100)
    end
    expect(post.reload.log_version).to eq 1
    expect(post.log_size).to eq 1
    expect(post.log_data.versions.last.changes)
      .to include("title" => "Triggers", "rating" => 100)
  end

  it "merges the logs within timeline", :aggregate_failures do
    post = nil
    Timecop.freeze(Time.at(1_000_000)) do
      post = Post.create!(title: "Triggers", rating: 10)
    end
    Timecop.freeze(Time.at(1_000_100)) do
      post.update!(rating: 100)
    end
    expect(post.reload.log_version).to eq 2
    expect(post.log_size).to eq 2
    Timecop.freeze(Time.at(1_000_101)) do
      post.update!(title: "Debounced")
    end
    expect(post.reload.log_version).to eq 2
    expect(post.log_size).to eq 2
    expect(post.log_data.versions.last.changes)
      .to include("title" => "Debounced", "rating" => 100)

    Timecop.freeze(Time.at(1_000_120)) do
      post.update!(active: true)
    end

    expect(post.reload.log_version).to eq 3
    expect(post.log_size).to eq 3
  end
end

describe "trigger debounce", :db do
  describe "before update or insert" do
    include_context "trigger_debounce_context"
  end

  describe "after update or insert" do
    include_context "trigger_debounce_context", "--after_trigger"
  end
end
