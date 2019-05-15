# frozen_string_literal: true

require "spec_helper"

describe Logidze::Model, :db do
  let(:user) do
    User.create!(
      name: "test",
      age: 10,
      active: false,
      log_data: {
        "v" => 5,
        "h" =>
          [
            {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil}},
            {"v" => 2, "ts" => time(200), "c" => {"active" => true}},
            {"v" => 3, "ts" => time(200), "r" => 1, "c" => {"name" => "test"}, "m" => {"some_key" => "old_val"}},
            {"v" => 4, "ts" => time(300), "c" => {"age" => 0}},
            {"v" => 5, "ts" => time(400), "c" => {"age" => 10, "active" => false}, "m" => {"_r" => 2, "some_key" => "current_val"}}
          ]
      }
    )
  end

  describe "#at(time)" do
    it "returns version at specified time", :aggregate_failures do
      user_old = user.at(time: time(350))
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "returns nil if time is invalid (too early)" do
      expect(user.at(time: time(99))).to be_nil
    end

    it "returns self if actual version" do
      expect(user.at(time: time(401))).to be_equal(user)
    end

    it "returns dup", :aggregate_failures do
      user_old = user.at(time: time(100))
      expect(user_old).not_to be_equal(user)

      user_old.age = 100
      expect(user.age).to eq 10
    end

    it "retains original object's id" do
      user_old = user.at(time: time(100))
      expect(user_old.id).to be_equal(user.id)
    end

    it "handles time as string", :aggregate_failures do
      user_old = user.at(time: "2016-04-12 12:05:50")
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "handles time as Time", :aggregate_failures do
      user_old = user.at(time: Time.new(2016, 0o4, 12, 12, 0o5, 50))
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "handles time as Date", :aggregate_failures do
      user_old = user.at(time: Date.new(2016, 0o4, 13))
      expect(user_old).to be_equal user
    end
  end

  describe "#at(version)" do
    it "returns specified version", :aggregate_failures do
      user_old = user.at(version: 4)
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end
  end

  describe "#at!" do
    it "update object in-place", :aggregate_failures do
      user.at!(time: time(350))

      expect(user.name).to eq "test"
      expect(user.age).to eq 0
      expect(user.active).to eq true

      expect(user.changes).to include("age" => [10, 0], "active" => [false, true])
    end
  end

  describe "#diff_from" do
    it "returns diff from specified time" do
      expect(user.diff_from(time: time(350)))
        .to eq(
          "id" => user.id,
          "changes" =>
            {
              "age" => {"old" => 0, "new" => 10},
              "active" => {"old" => true, "new" => false}
            }
        )
    end
  end

  describe "undo!" do
    it "revert record to previous state", :aggregate_failures do
      expect(user.undo!).to eq true
      user.reload
      expect(user.name).to eq "test"
      expect(user.age).to eq 0
      expect(user.active).to eq true
    end

    it "revert record several times", :aggregate_failures do
      user.undo!
      expect(user.reload.age).to eq 0

      user.undo!
      expect(user.age).to be_nil

      user.undo!
      expect(user.name).to be_nil

      user.undo!
      user.reload

      expect(user.name).to be_nil
      expect(user.age).to be_nil
      expect(user.active).to be_nil
    end

    it "return false no possible undo" do
      u = User.create!(
        log_data: {
          "v" => 1,
          "h" =>
          [
            {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil}}
          ]
        }
      )

      expect(u.undo!).to eq false
    end
  end

  describe "redo!" do
    before do
      user.undo!
      user.reload
    end

    it "revert record to future state", :aggregate_failures do
      expect(user.redo!).to eq true
      user.reload
      expect(user.name).to eq "test"
      expect(user.age).to eq 10
      expect(user.active).to eq false
    end

    it "revert record several times", :aggregate_failures do
      user.undo!
      user.reload

      expect(user.name).to eq "test"
      expect(user.age).to be_nil
      expect(user.active).to eq true

      user.redo!
      user.redo!
      user.reload

      expect(user.name).to eq "test"
      expect(user.age).to eq 10
      expect(user.active).to eq false
    end

    it "return false no possible redo" do
      u = User.create!(
        log_data: {
          "v" => 1,
          "h" =>
          [
            {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil}}
          ]
        }
      )

      expect(u.redo!).to eq false
    end
  end

  describe "#switch_to!" do
    it "revert record to the specified version", :aggregate_failures do
      expect(user.switch_to!(3)).to eq true
      user.reload
      expect(user.log_version).to eq 3
      expect(user.name).to eq "test"
      expect(user.age).to be_nil
      expect(user.active).to eq true
    end

    it "return false if version is unknown" do
      expect(user.switch_to!(10)).to eq false
    end
  end

  describe ".at" do
    before { user }

    it "returns reverted records", :aggregate_failures do
      u = User.at(time: time(350)).first

      expect(u.name).to eq "test"
      expect(u.age).to eq 0
      expect(u.active).to eq true
    end

    it "returns reverted records when called on relation", :aggregate_failures do
      u = User.where(active: false).order(age: :desc).at(time: time(350)).first

      expect(u.name).to eq "test"
      expect(u.age).to eq 0
      expect(u.active).to eq true
    end

    it "skips nil records" do
      User.create!(
        log_data: {
          "v" => 1,
          "h" =>
            [
              {"v" => 1, "ts" => time(400), "c" => {"name" => nil, "age" => nil, "active" => nil}}
            ]
        }
      )

      expect(User.at(time: time(350)).size).to eq 1
    end
  end

  describe ".diff_from" do
    before { user }

    it "returns diffs for records", :aggregate_failures do
      expect(
        User.diff_from(time: time(350)).first
      ).to eq(
        "id" => user.id,
        "changes" =>
          {
            "age" => {"old" => 0, "new" => 10},
            "active" => {"old" => true, "new" => false}
          }
      )
    end

    it "returns diffs for records when called on relation", :aggregate_failures do
      expect(
        User.where(active: false).order(age: :desc).diff_from(time: time(350)).first
      ).to eq(
        "id" => user.id,
        "changes" =>
          {
            "age" => {"old" => 0, "new" => 10},
            "active" => {"old" => true, "new" => false}
          }
      )
    end
  end

  describe "#responsible_id" do
    it "returns id for current version" do
      expect(user.log_data.responsible_id).to eq 2
    end

    it "returns nil if no information" do
      expect(user.at(time: time(350)).log_data.responsible_id).to be_nil
    end

    it "returns id for previous version" do
      expect(user.at(time: time(250)).log_data.responsible_id).to eq 1
    end
  end

  describe "#meta" do
    it "returns meta for current version" do
      expect(user.log_data.meta).to eq("_r" => 2, "some_key" => "current_val")
    end

    it "returns nil if no information" do
      expect(user.at(time: time(350)).log_data.meta).to be_nil
    end

    it "returns meta for previous version" do
      expect(user.at(time: time(250)).log_data.meta).to eq("some_key" => "old_val")
    end
  end

  describe ".reload_log_data" do
    it "returns log_data" do
      expect(User).to receive(:where).and_call_original
      expect(user.reload_log_data).to eq(user.log_data)
    end
  end

  context "Versioned associations" do
    before(:all) { Logidze.associations_versioning = true }

    let(:user) do
      User.create(
        name: "John Doe",
        age: 35,
        active: true,
        log_data: {
          "v" => 4,
          "h" =>
            [
              {"v" => 1, "ts" => time(50), "c" => {"name" => "John Harris", "active" => false, "age" => 45}},
              {"v" => 2, "ts" => time(150), "c" => {"active" => true, "age" => 34}},
              {"v" => 3, "ts" => time(300), "c" => {"name" => "John Doe Jr.", "age" => 35}},
              {"v" => 4, "ts" => time(350), "c" => {"name" => "John Doe"}}
            ]
        }
      )
    end

    let(:article) do
      article = Article.create(
        title: "Post",
        rating: 5,
        active: true,
        user: user,
        log_data: {
          "v" => 4,
          "h" =>
            [
              {"v" => 1, "ts" => time(25), "c" => {"title" => "Anonymous inactive", "active" => false, :user_id => nil}},
              {"v" => 2, "ts" => time(100), "c" => {"title" => "Cool article", "active" => false, :user_id => user.id}},
              {"v" => 3, "ts" => time(200), "c" => {"title" => "Article", "active" => true}},
              {"v" => 4, "ts" => time(300), "c" => {"rating" => 5, "title" => "Post"}}
            ]
        }
      )
      article.comments.create(
        content: "New comment",
        log_data: {
          "v" => 2,
          "h" =>
        [
          {"v" => 1, "ts" => time(150), "c" => {"content" => "My comment"}},
          {"v" => 2, "ts" => time(250), "c" => {"content" => "New comment"}}
        ]
        }
      )
      article.comments.create(
        content: "New comment 2",
        log_data: {
          "v" => 1,
          "h" =>
        [
          {"v" => 1, "ts" => time(230), "c" => {"content" => "New comment 2"}}
        ]
        }
      )

      article
    end

    let(:old_article) { article.at(time: time(200)) }
    let(:very_old_article) { article.at(time: time(100)) }

    context "when feature is disabled" do
      before(:all) { Logidze.associations_versioning = false }

      describe "belongs_to" do
        it "returns not versioned association" do
          expect(old_article.user.name).to eql(user.name)
          expect(very_old_article.user.age).to eql(user.age)
        end
      end

      describe "has_many" do
        it "returns not versioned association" do
          expect(old_article.comments.first.content).to eql("New comment")
        end
      end
    end

    context "when feature is enabled" do
      before(:all) { Logidze.associations_versioning = true }
      after(:all) { Logidze.associations_versioning = false }

      context "belongs_to" do
        context "when the association wasn't set in the past version" do
          let(:first_article_revision) { article.at(version: 1) }

          it "returns nil" do
            expect(first_article_revision.user).to be_nil
          end
        end

        it "returns association version, according to the owner" do
          expect(old_article.user.name).to eql("John Harris")
          expect(very_old_article.user.age).to eql(45)
        end

        context "#at(version)" do
          let(:old_article) { article.at(version: 3) }

          specify { expect(old_article.user.name).to eql("John Harris") }
        end

        context "when owner was not changed at the given time" do
          it "still returns association version" do
            # this returns the same article object due to implementation
            not_changed_article = article.at(time: time(330))
            expect(not_changed_article.user.name).to eql("John Doe Jr.")
          end
        end
      end

      describe "has_many" do
        it "returns association version, according to the owner" do
          expect(old_article.comments.first.content).to eql("My comment")
        end

        it "responds to #length correctly" do
          expect(very_old_article.comments.length).to eql(0)
        end

        it "returns not versioned association #size, due to AR implementaion" do
          expect(very_old_article.comments.size).to eql(2)
        end

        it "it responds to #item_ids correctly" do
          id = article.comments.first.id
          expect(old_article.comment_ids).to match_array([id])
        end

        context "#at(version)" do
          let(:old_article) { article.at(version: 3) }

          specify { expect(old_article.comments.first.content).to eql("My comment") }
        end

        describe "Presence-like methods" do
          it "responds to #empty? correctly" do
            expect(old_article.comments.empty?).to be false
            expect(very_old_article.comments.empty?).to be true
          end

          it "responds to #any? correctly" do
            expect(old_article.comments.any?).to be true
            expect(very_old_article.comments.any?).to be false
          end

          it "responds to #many? correctly" do
            expect(old_article.comments.any?).to be true
            expect(very_old_article.comments.any?).to be false
          end

          it "responds to #blank? correctly" do
            expect(old_article.comments.blank?).to be false
            expect(very_old_article.comments.blank?).to be true
          end
        end

        it "sets inversed association properly" do
          old_comment = old_article.comments.first
          expect(old_comment.article.title).to eql("Article")
        end
      end
    end
  end

  context "Serialized types" do
    let(:user) do
      User.create!(
        name: "test",
        extra: {gender: "X", social: {fb: [1, 2], vk: false}},
        settings: %i[sms mail],
        log_data: {
          "v" => 5,
          "h" =>
            [
              {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil, "extra" => nil, "settings" => nil}},
              {"v" => 2, "ts" => time(200), "c" => {"extra" => {"gender" => "M", "social" => {"fb" => [1]}}.to_json}},
              {"v" => 3, "ts" => time(200), "r" => 1, "c" => {"settings" => "{mail}"}},
              {"v" => 4, "ts" => time(300), "c" => {"extra" => {"gender" => "F", "social" => {"fb" => [2]}}.to_json}},
              {"v" => 5, "ts" => time(400), "r" => 2, "c" => {"extra" => {"gender" => "X", "social" => {"fb" => [1, 2], "vk" => false}}.to_json, "settings" => "{sms,mail}"}}
            ]
        }
      )
    end

    describe "#at" do
      it "returns version at specified time", :aggregate_failures do
        user_old = user.at(time: time(350))
        expect(user_old.extra["gender"]).to eq "F"
        expect(user_old.extra["social"]).to eq("fb" => [2])
        expect(user_old.settings).to eq(["mail"])

        user_old = user.at(time: time(250))
        expect(user_old.extra["gender"]).to eq "M"
        expect(user_old.extra["social"]).to eq("fb" => [1])
        expect(user_old.settings).to eq(["mail"])
      end
    end

    describe "#diff_from" do
      it "returns diff from specified time" do
        expect(user.diff_from(version: 3))
          .to eq(
            "id" => user.id,
            "changes" =>
              {
                "extra" => {"old" => {"gender" => "M", "social" => {"fb" => [1]}}, "new" => {"gender" => "X", "social" => {"fb" => [1, 2], "vk" => false}}},
                "settings" => {"old" => ["mail"], "new" => %w[sms mail]}
              }
          )
      end
    end
  end

  context "Schema changes" do
    let(:user) do
      User.create!(
        name: "test",
        log_data: {
          "v" => 3,
          "h" =>
            [
              {"v" => 1, "ts" => time(100), "c" => {"age" => nil}},
              {"v" => 2, "ts" => time(120), "c" => {"age" => 1, "last_name" => "Harry"}},
              {"v" => 3, "ts" => time(200), "c" => {"name" => "Harry", "age" => 10}}
            ]
        }
      )
    end

    describe "#at" do
      it "returns version at specified time", :aggregate_failures do
        user_old = user.at(time: time(150))
        expect(user_old.name).to eq "test"
        expect(user_old.age).to eq 1
      end
    end

    describe "#diff_from" do
      it "returns diff from specified time" do
        expect(user.diff_from(version: 1))
          .to eq(
            "id" => user.id,
            "changes" =>
              {
                "age" => {"old" => nil, "new" => 10},
                "name" => {"old" => nil, "new" => "Harry"}
              }
          )
      end
    end
  end

  describe "#log_size" do
    subject { user.log_size }

    it { is_expected.to eq(user.log_data.size) }

    context "when model created within a without_logging block" do
      let(:user) { User.create!(name: "test") }

      before { Logidze.without_logging { user } }

      it { is_expected.to be_zero }
    end
  end

  describe ".reset_log_data" do
    let!(:user2) { user.dup.tap(&:save!) }
    let!(:user3) { user.dup.tap(&:save!) }

    before { User.limit(2).reset_log_data }

    it "nullify log_data column for a association" do
      expect(user.reload.log_size).to be_zero
      expect(user2.reload.log_size).to be_zero
    end

    it "not affect other model records" do
      expect(user3.reload.log_size).to eq 5
    end
  end

  describe "#reset_log_data" do
    subject { user.log_size }

    before { user.reset_log_data }

    it "nullify log_data column for a single record" do
      is_expected.to be_zero
    end
  end
end
