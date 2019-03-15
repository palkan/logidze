# frozen_string_literal: true
require "spec_helper"
require "acceptance_helper"

describe Logidze::IgnoreLogData, :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"
      successfully "rails generate logidze:model post"
      successfully "rails generate logidze:model post_comment"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  let(:user) { User.create! }
  let!(:post) { NotLoggedPost.create!(user: user) }

  describe "#update!" do
    it "updates log_data" do
      expect do
        NotLoggedPost.find(post.id).update!(title: "new")
      end.to change { Post.find(post.id).log_data.version }.by(1)
    end
  end

  describe "#log_data" do
    shared_examples "test loads #log_data" do
      it "loads log_data" do
        expect(subject.log_data).not_to be_nil
        expect(subject.log_data).to be_a(Logidze::History)
      end
    end

    shared_examples "test raises error when #log_data is called" do
      it "raises error when #log_data is called" do
        expect { subject.reload.log_data }.to raise_error(ActiveModel::MissingAttributeError)
      end
    end

    context "when Logidze.ignore_log_data_by_default = true" do
      before(:all) { Logidze.ignore_log_data_by_default = true }
      after(:all) { Logidze.ignore_log_data_by_default = false }

      subject { Post.create! }

      include_examples "test raises error when #log_data is called"

      context "when inside Logidze.with_log_data block" do
        it "loads log_data" do
          Logidze.with_log_data do
            expect(subject.reload.log_data).not_to be_nil
          end
        end
      end
    end

    context "when model is configured with has_logidze(ignore_log_data: false)" do
      context "when Logidze.ignore_log_data_by_default = true" do
        before(:all) { Logidze.ignore_log_data_by_default = true }
        after(:all) { Logidze.ignore_log_data_by_default = false }

        subject { AlwaysLoggedPost.find(post.id) }
        include_examples "test loads #log_data"
      end
    end

    context "when model is configured with has_logidze(ignore_log_data: true)" do
      shared_context "test #reload_log_data" do
        context "#reload_log_data" do
          it "loads data from DB" do
            expect(subject.reload_log_data).not_to be_nil
            expect(subject.log_data).not_to be_nil
          end

          it "deserializes log_data properly" do
            expect(subject.reload_log_data).to be_a(Logidze::History)
          end
        end
      end

      context "with default scope" do
        subject { NotLoggedPost.find(post.id) }

        include_examples "test raises error when #log_data is called"
        include_context "test #reload_log_data"
      end

      context ".with_log_data" do
        subject { NotLoggedPost.with_log_data.find(post.id) }

        include_examples "test loads #log_data"
      end

      describe ".eager_load" do
        subject(:model) { User.eager_load(:not_logged_posts).last.not_logged_posts.last }

        include_examples "test raises error when #log_data is called"
        include_context "test #reload_log_data"
      end
    end

    describe "associations" do
      context "when owner has loaded log_data" do
        before { post.comments.create(content: 'New comment') }

        subject do
          loaded = NotLoggedPost.with_log_data.find(post.id)
          loaded.comments[0]
        end

        include_examples "test loads #log_data"
      end
    end
  end
end
