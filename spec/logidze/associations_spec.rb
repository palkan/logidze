# frozen_string_literal: true

require "spec_helper"

describe Logidze::VersionedAssociation, :db do
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

      it "returns not versioned association #size, due to AR implementation" do
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
