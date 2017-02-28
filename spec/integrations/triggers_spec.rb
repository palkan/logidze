# frozen_string_literal: true
require "acceptance_helper"

describe "Logidze triggers", :db do
  it 'cannot be used with both whitelist and blacklist options' do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      unsuccessfully "rails generate logidze:model post "\
                     "--whitelist=title --blacklist=created_at"
    end
  end

  context 'without blacklisting' do
    include_context "cleanup migrations"

    before(:all) do
      @old_post = Post.create!(title: 'First', rating: 100, active: true)
      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:install"
        successfully "rails generate logidze:model post --limit 4 --backfill"
        successfully "rails generate logidze:model user --limit 4 --backfill --only-trigger"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    after(:all) { @old_post.destroy! }

    let(:post_params) { { title: 'Triggers', rating: 10, active: false } }
    let(:user_params) { { name: 'Triggers',  age: 20,    active: false } }

    describe "backfill" do
      let(:post) { Post.find(@old_post.id) }

      it "creates snapshot for existent records", :aggregate_failures do
        expect(post.log_version).to eq 1
        expect(post.log_size).to eq 1
      end
    end

    describe "insert" do
      let(:post) { Post.create!(post_params).reload }
      let(:user) { User.create!(user_params).reload }

      it "creates initial version", :aggregate_failures do
        expect(post.log_version).to eq 1
        expect(post.log_size).to eq 1
      end

      it "sets version timestamp to now()", :aggregate_failures do
        expect(post.log_data.current_version.time / 1000).to eq(Time.current.to_i)
        expect(user.log_data.current_version.time / 1000).to eq(Time.current.to_i)
      end

      context "when logging is disabled" do
        let(:post) { Post.without_logging { Post.create!.reload } }

        it "doesn't create initial version" do
          expect(post.log_data).to be_nil
        end
      end
    end

    describe "update" do
      before(:all) do
        @post = Post.create!
        @user = User.create!
      end

      after(:all) do
        @post.destroy!
        @user.destroy!
      end

      let(:post) { @post.reload }
      let(:user) { @user.reload }

      it "creates new version", :aggregate_failures do
        post.update!(post_params)
        expect(post.reload.log_version).to eq 2
        expect(post.log_size).to eq 2
      end

      it "creates several versions", :aggregate_failures do
        post.update!(post_params)
        expect(post.log_version).to eq 1

        post.update!(rating: 0)
        expect(post.log_version).to eq 1

        expect(post.reload.log_version).to eq 3

        Post.where(id: post.id).update_all(active: true)
        expect(post.reload.log_version).to eq 4
      end

      it "doesn't create new version if values not changed", :aggregate_failures do
        Post.where(id: post.id).update_all(rating: nil)
        expect(post.reload.log_version).to eq 1
        expect(post.log_size).to eq 1
      end

      it "sets version timestamp to now() when updated_at column does not exist" do
        user.update!(user_params)
        expect(user.reload.log_data.current_version.time / 1000).to eq(Time.current.to_i)
      end

      it "sets version timestamp to updated_at when updated_at column exists" do
        Timecop.freeze(Time.at(0)) { post.update!(post_params) }
        expect(post.reload.log_data.current_version.time / 1000).to eq(Time.at(0).to_i)
      end

      context "logging is disabled" do
        it "doesn't create new version" do
          Logidze.without_logging do
            post.update!(post_params)
            expect(post.reload.log_version).to eq 1
            expect(post.log_size).to eq 1
          end

          post.update!(rating: 12)
          expect(post.reload.log_version).to eq 2
          expect(post.log_size).to eq 2
        end

        it "handles failed transaction" do
          post.errored = true
          expect(post).not_to be_valid

          ignore_exceptions do
            Logidze.without_logging do
              post.update!(post_params)
            end
          end

          expect(post.reload.log_version).to eq 1
          expect(post.log_size).to eq 1
          expect(post).to be_valid

          post.update!(rating: 12)
          expect(post.reload.log_version).to eq 2
          expect(post.log_size).to eq 2
        end
      end

      context "log_data is empty" do
        let(:post) { Post.without_logging { Post.create!(post_params).reload } }

        it "creates several versions", :aggregate_failures do
          post.update!(rating: 0)
          post.update!(title: 'Updated')
          expect(post.log_data).to be_nil

          expect(post.reload.log_version).to eq 2

          Post.where(id: post.id).update_all(active: true)
          expect(post.reload.log_version).to eq 3
        end
      end
    end

    describe "undo/redo" do
      before(:all) { @post = Post.create!(title: 'Triggers', rating: 10) }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "undo and redo" do
        post.update!(rating: 5)
        post.update!(title: 'Good Triggers')

        expect(post.reload.log_version).to eq 3
        expect(post.log_size).to eq 3

        post.undo!
        expect(post.reload.log_version).to eq 2
        expect(post.log_size).to eq 3
        expect(post.title).to eq 'Triggers'
        expect(post.rating).to eq 5

        post.undo!
        expect(post.reload.log_version).to eq 1
        expect(post.log_size).to eq 3
        expect(post.title).to eq 'Triggers'
        expect(post.rating).to eq 10

        post.redo!
        expect(post.reload.log_version).to eq 2
        expect(post.log_size).to eq 3
        expect(post.title).to eq 'Triggers'
        expect(post.rating).to eq 5

        post.redo!
        expect(post.reload.log_version).to eq 3
        expect(post.log_size).to eq 3
        expect(post.title).to eq 'Good Triggers'
        expect(post.rating).to eq 5
      end

      it "removes future version when updated after undo" do
        post.update!(rating: 5)
        post.reload.undo!

        expect(post.reload.log_version).to eq 1
        expect(post.log_size).to eq 2
        expect(post.rating).to eq 10

        post.update!(title: 'No Future')
        expect(post.reload.log_version).to eq 2
        expect(post.log_size).to eq 2

        post.undo!
        expect(post.reload.log_version).to eq 1
        expect(post.log_size).to eq 2
        expect(post.rating).to eq 10
        expect(post.title).to eq "Triggers"
      end

      it "there and back again" do
        post.update!(rating: 5)

        post_was = post.reload

        post.undo!
        post.redo!
        expect(post.reload).to eq post_was
      end
    end

    describe "limit" do
      before(:all) { @post = Post.create!(title: 'Triggers', rating: 10) }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "stores limited number of logs", :aggregate_failures do
        post.update!(active: true)
        post.update!(rating: 22)
        post.update!(title: "Limit")

        expect(post.reload.log_version).to eq 4
        expect(post.log_size).to eq 4

        post.update!(rating: nil)
        expect(post.reload.log_version).to eq 5
        expect(post.log_size).to eq 4
        expect(post.log_data.versions.first.changes).
          to include("title" => "Triggers", "rating" => 10, "active" => true)

        post.update!(rating: 20)
        expect(post.reload.log_version).to eq 6
        expect(post.log_size).to eq 4
        expect(post.log_data.versions.first.changes).
          to include("title" => "Triggers", "rating" => 22, "active" => true)
      end
    end
  end

  context 'with blacklist' do
    include_context "cleanup migrations"

    before(:all) do
      @blacklist = %w(created_at active)

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:install"
        successfully "rails generate logidze:model post "\
                     "--blacklist=#{@blacklist.join(' ')}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    let(:post_params) { { title: 'Triggers', rating: 10, active: false } }

    describe "insert" do
      let(:post) { Post.create!(post_params).reload }

      it "does not log blacklisted columns", :aggregate_failures do
        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array Post.column_names - @blacklist - ['log_data']
      end
    end

    describe "update" do
      before(:all) { @post = Post.create! }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "does not log blacklisted columns", :aggregate_failures do
        post.update!(post_params)
        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array Post.column_names - @blacklist - ['log_data']
      end
    end
  end

  context 'with whitelist' do
    include_context "cleanup migrations"

    before(:all) do
      @whitelist = %w(title rating)

      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:install"
        successfully "rails generate logidze:model post "\
                     "--whitelist=#{@whitelist.join(' ')}"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    let(:post_params) { { title: 'Triggers', rating: 10, active: false } }

    describe "insert" do
      let(:post) { Post.create!(post_params).reload }

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
        post.update!(post_params)
        changes = post.log_data.current_version.changes
        expect(changes.keys).to match_array @whitelist
      end
    end
  end
end
