# frozen_string_literal: true
require "acceptance_helper"

describe "Logidze timestamps", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  before do
    Timecop.freeze(Time.at(1_000_000)) do
      post.update!(rating: 100)
      user.update!(time: Time.current)
    end
    post.reload
    user.reload
  end

  let(:post) { Post.create!(updated_at: Time.at(0)).reload }
  let(:user) { User.create!(time: Time.at(0)).reload }

  context "timestamp_column is not set" do
    include_context "setup models with timestamp column", nil

    it "uses 'updated_at' column if it exists", :aggregate_failures do
      expect(post).to use_timestamp(:updated_at)
      expect(user).to use_statement_timestamp
    end

    it "sets version timestamp to statement_timestamp() upon insertion" do
      expect(Post.create!.reload).to use_statement_timestamp
    end

    it "sets version timestamp to statement_timestamp() if 'updated_at' did not change" do
      Timecop.freeze(Time.at(2_000_000)) { Post.where(id: post.id).update_all(rating: nil) }
      expect(post.reload).to use_statement_timestamp
    end
  end

  context "timestamp_column is set to 'time'" do
    include_context "setup models with timestamp column", "time"

    it "uses 'time' column if it exists", :aggregate_failures do
      expect(post).to use_statement_timestamp
      expect(user).to use_timestamp(:time)
    end
  end

  context "timestamp_column is 'nil'" do
    # 'nil', 'null' and 'false' are identical
    include_context "setup models with timestamp column", "nil"

    it "uses statement_timestamp()", :aggregate_failures do
      expect(user).to use_statement_timestamp
      expect(user).to use_statement_timestamp
    end
  end
end
