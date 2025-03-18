# frozen_string_literal: true

require "acceptance_helper"

describe "triggers", :db do
  include_context "cleanup migrations"

  before(:all) do
    @old_post = Post.create!(title: "First", rating: 100, active: true)
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:model post --limit 4 --backfill #{LOGIDZE_DETACHED ? " --detached" : ""}"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
  end

  after(:all) { @old_post.destroy! }

  let(:params) { {title: "Triggers", rating: 10, active: false, meta: {tags: %w[some tag]}, data: {some: "json"}} }

  describe "backfill" do
    let(:post) { Post.find(@old_post.id) }

    it "creates snapshot for existent records", :aggregate_failures do
      expect(post.log_version).to eq 1
      expect(post.log_size).to eq 1
      expect(post.log_data.versions.last.changes.keys)
        .not_to include("log_data")
    end
  end

  describe "insert" do
    let(:post) { Post.create!(params).reload }

    it "creates initial version", :aggregate_failures do
      expect(post.log_version).to eq 1
      expect(post.log_size).to eq 1
      expect(post.log_data.versions.last.changes.keys)
        .not_to include("log_data")
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
      post.update!(meta: {tags: ["other"]})
      diff = post.reload.diff_from(version: (post.reload.log_version - 1))["changes"]
      expected_diff_meta = {
        "old" => {"tags" => %w[some tag]},
        "new" => {"tags" => %w[other]}
      }
      expect(diff["meta"]["new"].class).to eq diff["meta"]["old"].class
      expect(diff["meta"]).to eq expected_diff_meta
    end

    it "generates the correct diff on fallback", :aggregate_failures do
      post.update!(title: "3981465518e9665560300635", meta: {tags: ["other"]})
      diff = post.reload.diff_from(version: (post.reload.log_version - 1))["changes"]
      expected_diff_title = {
        "old" => "Triggers",
        "new" => "3981465518e9665560300635"
      }
      expected_diff_meta = {
        "old" => {"tags" => %w[some tag]},
        "new" => {"tags" => %w[other]}
      }
      expect(diff["meta"]["new"].class).to eq diff["meta"]["old"].class
      expect(diff["meta"]).to eq expected_diff_meta
      expect(diff["title"]).to eq expected_diff_title

      snapshot = JSON.parse(post.raw_log_data)
      expect(snapshot["h"].first).to include({
        "c" => a_hash_including({"meta" => '{"tags": ["some", "tag"]}'})
      })
    end

    it "works with json columns", :aggregate_failures do
      post.update!(data: {other: "json"})
      diff = post.reload.diff_from(version: (post.reload.log_version - 1))["changes"]
      expected_diff_data = {
        "old" => {"some" => "json"},
        "new" => {"other" => "json"}
      }
      expect(diff["data"]["new"].class).to eq diff["data"]["old"].class
      expect(diff["data"]).to eq expected_diff_data
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
      expect(post.log_version).to eq 1
      post.update!(params)
      expect(post.log_version).to eq 1

      post.update!(rating: 0)
      expect(post.log_version).to eq 1

      expect(post.reload.log_version).to eq 3

      Post.where(id: post.id).update_all(active: true)
      expect(post.reload.log_version).to eq 4
    end

    it "does not raise exception on number overflow", :aggregate_failures do
      post.update!(title: "3981465518e9665560300635")

      expect(post.reload.log_version).to eq 2
      expect(post.title).to eq "3981465518e9665560300635"
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
        expect(post.log_data).to be_nil
        post.update!(rating: 0)
        post.update!(title: "Updated")
        expect(post.log_data).to be_nil

        expect(post.reload.log_version).to eq 2

        Post.where(id: post.id).update_all(active: true)
        expect(post.reload.log_version).to eq 3
      end
    end

    context "with unicode changes" do
      let(:post) { Post.create! params }

      it "handles unicode characters" do
        post.update!(meta: {tags: %w[ロギング は楽しい]})
        post.update!(title: "Spaß")

        expect(post.reload.log_version).to eq 3
        expect(post.log_size).to eq 3

        post2 = post.at(version: 2)
        expect(post2.title).to eq "Triggers"
        expect(post2.meta["tags"]).to eq %w[ロギング は楽しい]

        post1 = post.at(version: 1)

        expect(post1.title).to eq "Triggers"
        expect(post1.meta["tags"]).to eq %w[some tag]
      end
    end
  end

  describe "undo/redo" do
    before(:all) { @post = Post.create!(title: "Triggers", rating: 10) }
    after(:all) { @post.destroy! }

    let(:post) { @post.reload }

    it "undo and redo" do
      post.update!(rating: 5)
      post.update!(title: "Good Triggers")

      expect(post.reload.log_version).to eq 3
      expect(post.log_size).to eq 3

      post.undo!
      expect(post.reload.log_version).to eq 2
      expect(post.log_size).to eq 3
      expect(post.title).to eq "Triggers"
      expect(post.rating).to eq 5

      post.undo!
      expect(post.reload.log_version).to eq 1
      expect(post.log_size).to eq 3
      expect(post.title).to eq "Triggers"
      expect(post.rating).to eq 10

      post.redo!
      expect(post.reload.log_version).to eq 2
      expect(post.log_size).to eq 3
      expect(post.title).to eq "Triggers"
      expect(post.rating).to eq 5

      post.redo!
      expect(post.reload.log_version).to eq 3
      expect(post.log_size).to eq 3
      expect(post.title).to eq "Good Triggers"
      expect(post.rating).to eq 5
    end

    it "removes future version when updated after undo" do
      post.update!(rating: 5)
      post.reload.undo!

      expect(post.reload.log_version).to eq 1
      expect(post.log_size).to eq 2
      expect(post.rating).to eq 10

      post.update!(title: "No Future")
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
    before(:all) { @post = Post.create!(title: "Triggers", rating: 10, data: {some: "json"}) }
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

    it "handles JSONB correctly when append: true", :aggregate_failures do
      post.update!(rating: 5, meta: {tags: %w[jsonb json]}, data: {json: "here"})
      post.reload.switch_to!(1, append: true)
      post.reload

      expect(post.log_version).to eq 3
      expect(post.log_size).to eq 3
      expect(post.rating).to eq 10
      expect(post.data).to eq({"some" => "json"})
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
    before(:all) { @post = Post.create!(title: "Triggers", rating: 10) }
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

  describe ".with_full_snapshot" do
    before(:all) { @post = Post.create!(title: "Triggers", rating: 10) }
    after(:all) { @post.destroy! }

    let(:post) { @post.reload }

    it "creates a new version with a full snapshot instead of a diff" do
      expect(post.log_version).to eq 1
      post.update!(title: "Full me")

      expect(post.reload.log_version).to eq 2

      Logidze.without_logging do
        post.update!(active: true)
        post.update!(rating: 22)
      end

      expect(post.reload.log_version).to eq 2

      expect(post.log_data.versions.last.changes)
        .to include("title" => "Full me")
      expect(post.log_data.versions.last.changes.keys)
        .not_to include("rating", "active")

      Logidze.with_full_snapshot { post.touch }

      expect(post.reload.log_version).to eq 3

      expect(post.log_data.versions.last.changes)
        .to include("title" => "Full me", "rating" => 22, "active" => true)
    end
  end
end
