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
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    after(:all) { @old_post.destroy! }

    let(:params) { { title: 'Triggers', rating: 10, active: false, meta: { tags: %w(some tag) } } }

    describe "backfill" do
      let(:post) { Post.find(@old_post.id) }

      it "creates snapshot for existent records", :aggregate_failures do
        expect(post.log_version).to eq 1
        expect(post.log_size).to eq 1
      end
    end

    describe "insert" do
      let(:post) { Post.create!(params).reload }

      it "creates initial version", :aggregate_failures do
        expect(post.log_version).to eq 1
        expect(post.log_size).to eq 1
      end

      context "when logging is disabled" do
        let(:post) { Post.without_logging { Post.create!.reload } }

        it "doesn't create initial version" do
          expect(post.log_data).to be_nil
        end
      end
    end

    # See https://github.com/palkan/logidze/pull/30
    describe "diff" do
      let(:post) { Post.create!(params).reload }

      it "generates the correct diff", :aggregate_failures do
        post.update!(meta: { tags: ['other'] })
        diff = post.reload.diff_from(version: (post.reload.log_version - 1))["changes"]
        expected_diff_meta = {
          "old" => { "tags" => %w(some tag) },
          "new" => { "tags" => %w(other) }
        }
        expect(diff["meta"]["new"].class).to eq diff["meta"]["old"].class
        expect(diff["meta"]).to eq expected_diff_meta
      end
    end

    describe "update" do
      before(:all) { @post = Post.create! }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "creates new version", :aggregate_failures do
        post.update!(params)
        expect(post.reload.log_version).to eq 2
        expect(post.log_size).to eq 2
      end

      it "creates several versions", :aggregate_failures do
        post.update!(params)
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

      context "logging is disabled" do
        it "doesn't create new version" do
          Logidze.without_logging do
            post.update!(params)
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
              post.update!(params)
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
        let(:post) { Post.without_logging { Post.create!(params).reload } }

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

      it "creates a new version when append: true" do
        post.update!(rating: 5)
        post.reload.undo!(append: true)

        expect(post.reload.log_version).to eq 3
        expect(post.log_size).to eq 3
        expect(post.rating).to eq 10
      end

      it "there and back again" do
        post.update!(rating: 5)

        post_was = post.reload

        post.undo!
        post.redo!
        expect(post.reload).to eq post_was
      end
    end

    describe "switch_to!" do
      before(:all) { @post = Post.create!(title: 'Triggers', rating: 10) }
      after(:all) { @post.destroy! }

      let(:post) { @post.reload }

      it "revers to specified version", :aggregate_failures do
        post.update!(rating: 5)
        post.reload.switch_to!(1)
        post.reload

        expect(post.log_version).to eq 1
        expect(post.log_size).to eq 2
      end

      it "creates a new version when append: true", :aggregate_failures do
        post.update!(rating: 5)
        post.reload.switch_to!(1, append: true)
        post.reload

        expect(post.log_version).to eq 3
        expect(post.log_size).to eq 3
        expect(post.rating).to eq 10
      end

      it "reverts to specified version if it's newer than current version", :aggregate_failures do
        post.update!(rating: 5)
        post.reload.undo!
        post.reload

        expect(post.log_version).to eq 1
        expect(post.log_size).to eq 2

        post.switch_to!(2, append: true)
        post.reload

        expect(post.log_version).to eq 2
        expect(post.log_size).to eq 2
      end

      context "append is disabled globally" do
        before(:all) { Logidze.append_on_undo = true }
        after(:all) { Logidze.append_on_undo = nil }

        it "creates a new version", :aggregate_failures do
          post.update!(rating: 5)
          post.reload.switch_to!(1)
          post.reload
          expect(post.log_version).to eq 3
          expect(post.log_size).to eq 3
          expect(post.rating).to eq 10
        end

        it "reverts to specified version when append: false", :aggregate_failures do
          post.update!(rating: 5)
          post.reload.switch_to!(1, append: false)
          post.reload
          expect(post.log_version).to eq 1
          expect(post.log_size).to eq 2
        end
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
        expect(post.log_data.versions.first.changes)
          .to include("title" => "Triggers", "rating" => 10, "active" => true)

        post.update!(rating: 20)
        expect(post.reload.log_version).to eq 6
        expect(post.log_size).to eq 4
        expect(post.log_data.versions.first.changes)
          .to include("title" => "Triggers", "rating" => 22, "active" => true)
      end
    end
  end

  context 'with blacklist' do
    include_context "cleanup migrations"

    before(:all) do
      @blacklist = %w(updated_at created_at active)

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

    let(:params) { { title: 'Triggers', rating: 10, active: false } }
    let(:updated_columns) { params.keys.map(&:to_s) }

    describe "insert" do
      let(:post) { Post.create!(params).reload }

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
        post.update!(params)
        changes = post.reload.log_data.current_version.changes
        expect(changes.keys).to match_array(updated_columns - @blacklist)
      end

      context "when only blacklisted columns are updated" do
        let(:params) { { active: false } }

        it "does not create new log entry", :aggregate_failures do
          old_log_size = post.log_data.size

          post.update!(params)

          expect(post.reload.log_data.size).to eq(old_log_size)
        end
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

    let(:params) { { title: 'Triggers', rating: 10, active: false } }

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

  context "updating trigger params" do
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

    let(:params) { { title: 'Triggers', rating: 10, active: false } }

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

      post2 = Post.create!(params).reload

      changes2 = post2.log_data.current_version.changes
      expect(changes2.keys).to match_array Post.column_names - %w(updated_at log_data)
    end
  end

  describe "with debounce_time" do
    include_context "cleanup migrations"

    before(:all) do
      Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
        successfully "rails generate logidze:install"
        successfully "rails generate logidze:model post --debounce_time=5000"
        successfully "rake db:migrate"

        # Close active connections to handle db variables
        ActiveRecord::Base.connection_pool.disconnect!
      end

      Post.reset_column_information
      # For Rails 4
      Post.instance_variable_set(:@attribute_names, nil)
    end

    it "stores limited number of logs", :aggregate_failures do
      post = nil
      Timecop.freeze(Time.at(1_000_000)) do
        post = Post.create!(title: 'Triggers', rating: 10)
      end
      Timecop.freeze(Time.at(1_000_100)) do
        post.update!(rating: 100)
      end
      expect(post.reload.log_version).to eq 2
      expect(post.log_size).to eq 2
      Timecop.freeze(Time.at(1_000_101)) do
        post.update!(title: "Debounced")
      end
      expect(post.reload.log_version).to eq 3
      expect(post.log_size).to eq 2
      expect(post.log_data.versions.last.changes)
        .to include("title" => "Debounced", "rating" => 100)

      Timecop.freeze(Time.at(1_000_120)) do
        post.update!(active: true)
      end

      expect(post.reload.log_version).to eq 4
      expect(post.log_size).to eq 3
    end
  end
end
