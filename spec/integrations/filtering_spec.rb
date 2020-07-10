# frozen_string_literal: true

require "acceptance_helper"

describe "columns filtering", :db do
  it "cannot be used with both whitelist and blacklist options" do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      unsuccessfully "rails generate logidze:model post "\
                     "--whitelist=title --blacklist=created_at"
    end
  end

  context "with blacklist" do
    include_context "cleanup migrations"

    before(:all) do
      @blacklist = %w[updated_at created_at active]

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:install"
        successfully "rails generate logidze:model post "\
                     "--blacklist=#{@blacklist.join(" ")}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    let(:params) { {title: "Triggers", rating: 10, active: false} }
    let(:updated_columns) { params.keys.map(&:to_s) }

    describe "insert" do
      let(:post) { Post.create!(params).reload }

      it "does not log blacklisted columns", :aggregate_failures do
        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array Post.column_names - @blacklist - ["log_data"]
      end
    end

    describe "update" do
      before(:all) { @post = Post.create! }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "does not log blacklisted columns", :aggregate_failures do
        post.update!(params)
        changes = post.reload.log_data.current_version.changes
        expect(changes.keys).to match_array(updated_columns - @blacklist)
      end

      context "when only blacklisted columns are updated" do
        let(:params) { {active: false} }

        it "does not create new log entry", :aggregate_failures do
          old_log_size = post.log_data.size

          post.update!(params)

          expect(post.reload.log_data.size).to eq(old_log_size)
        end
      end
    end
  end

  context "with whitelist" do
    include_context "cleanup migrations"

    before(:all) do
      @whitelist = %w[title rating]

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:install"
        successfully "rails generate logidze:model post "\
                     "--whitelist=#{@whitelist.join(" ")}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    let(:params) { {title: "Triggers", rating: 10, active: false} }

    describe "insert" do
      let(:post) { Post.create!(params).reload }

      it "logs only whitelisted columns", :aggregate_failures do
        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array @whitelist
      end
    end

    describe "update" do
      before(:all) { @post = Post.create! }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "logs only whitelisted columns", :aggregate_failures do
        post.update!(params)
        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array @whitelist
      end
    end
  end

  context "when adding filtering to the existing trigger" do
    include_context "cleanup migrations"

    before(:all) do
      @whitelist = %w[title rating]

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:install"
        successfully "rails generate logidze:model post "\
                     "--whitelist=#{@whitelist.join(" ")}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    let(:params) { {title: "Triggers", rating: 10, active: false} }

    it "logs with new params", :aggregate_failures do
      post = Post.create!(params).reload

      changes = post.log_data.current_version.changes
      expect(changes.keys).to match_array @whitelist

      ActiveRecord::Base.connection_pool.disconnect!

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model post --blacklist=updated_at --update"
        successfully "rake db:migrate"

        ActiveRecord::Base.connection_pool.disconnect!
      end

      # Start new transaction 'cause we closed the previous one on disconnect
      ActiveRecord::Base.connection.begin_transaction(joinable: false)
      post2 = Post.create!(params).reload

      changes2 = post2.log_data.current_version.changes
      expect(changes2.keys).to match_array Post.column_names - %w[updated_at log_data]
    end
  end
end
