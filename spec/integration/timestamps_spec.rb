# frozen_string_literal: true

require "acceptance_helper"

shared_context "log_timestamps_context" do |generator_arg|
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
    include_context "cleanup migrations"

    before(:all) do
      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        # Post has an 'updated_at' column
        successfully "rails generate logidze:model post #{generator_arg}"
        # User has a 'time' column
        successfully "rails generate logidze:model user #{generator_arg} --only-trigger"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end
    end

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
    include_context "cleanup migrations"

    before(:all) do
      param = "--timestamp_column time"
      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        # Post has an 'updated_at' column
        successfully "rails generate logidze:model post #{generator_arg} #{param}"
        # User has a 'time' column
        successfully "rails generate logidze:model user #{generator_arg} --only-trigger #{param}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end
    end

    it "uses 'time' column if it exists", :aggregate_failures do
      expect(post).to use_statement_timestamp
      expect(user).to use_timestamp(:time)
    end
  end

  context "timestamp_column is 'nil'" do
    include_context "cleanup migrations"

    before(:all) do
      # 'nil', 'null' and 'false' are identical
      param = "--timestamp_column nil"
      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        # Post has an 'updated_at' column
        successfully "rails generate logidze:model post #{generator_arg} #{param}"
        # User has a 'time' column
        successfully "rails generate logidze:model user #{generator_arg} --only-trigger #{param}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end
    end

    it "uses statement_timestamp()", :aggregate_failures do
      expect(user).to use_statement_timestamp
      expect(user).to use_statement_timestamp
    end
  end
end

describe "log timestamps", :db do
  describe "before update or insert" do
    include_context "log_timestamps_context"
  end

  describe "after update or insert" do
    include_context "log_timestamps_context", "--after_trigger"
  end
end
