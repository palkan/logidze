# frozen_string_literal: true

require "acceptance_helper"

describe "columns filtering", :db do
  it "cannot be used with both only and except options" do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      unsuccessfully "rails generate logidze:model post "\
                     "--only=title --except=created_at"
    end
  end

  context "with except" do
    include_context "cleanup migrations"

    before(:all) do
      @except = %w[updated_at created_at active]

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model post "\
                     "--except=#{@except.join(" ")}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
    end

    let(:params) { {title: "Triggers", rating: 10, active: false} }
    let(:updated_columns) { params.keys.map(&:to_s) }

    describe "insert" do
      let(:post) { Post.create!(params).reload }

      it "does not log excepted columns", :aggregate_failures do
        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array Post.column_names - @except - ["log_data"]
      end
    end

    describe "update" do
      before(:all) { @post = Post.create! }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "does not log excepted columns", :aggregate_failures do
        post.update!(params)
        changes = post.reload.log_data.current_version.changes
        expect(changes.keys).to match_array(updated_columns - @except)
      end

      context "when only excepted columns are updated" do
        let(:params) { {active: false} }

        it "does not create new log entry", :aggregate_failures do
          old_log_size = post.log_data.size

          post.update!(params)

          expect(post.reload.log_data.size).to eq(old_log_size)
        end
      end
    end
  end

  context "with only" do
    include_context "cleanup migrations"

    before(:all) do
      @only = %w[title meta]

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model post "\
                     "--only=#{@only.join(" ")}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
    end

    let(:params) { {title: "Triggers", rating: 10, active: false, meta: {some_id: "bla"}} }

    describe "insert" do
      let(:post) { Post.create!(params).reload }

      it "logs only onlyed columns", :aggregate_failures do
        changes = post.reload.log_data.current_version.changes
        expect(changes.keys).to match_array @only
      end
    end

    describe "update" do
      before(:all) { @post = Post.create! }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "logs only onlyed columns", :aggregate_failures do
        post.update!(params)
        changes = post.reload.log_data.current_version.changes
        expect(changes.keys).to match_array @only
      end

      it "handles jsonb fields updates", :aggregate_failures do
        post.update!(params)

        changes = post.reload.log_data.current_version.changes
        expect(changes.keys).to match_array @only

        post.update!(meta: {another: {id: "boom"}})

        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array @only
      end
    end
  end

  context "when adding filtering to the existing trigger" do
    include_context "cleanup migrations"

    before(:all) do
      @only = %w[title rating]

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model post "\
                     "--only=#{@only.join(" ")}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
    end

    let(:params) { {title: "Triggers", rating: 10, active: false} }

    it "logs with new params", :aggregate_failures do
      post = Post.create!(params).reload

      changes = post.log_data.current_version.changes
      expect(changes.keys).to match_array @only

      ActiveRecord::Base.connection_pool.disconnect!

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:model post --except=updated_at --update"
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
