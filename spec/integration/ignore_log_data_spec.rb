# frozen_string_literal: true

require "spec_helper"
require "acceptance_helper"

describe "ignore log columns", :db, skip: LOGIDZE_DETACHED do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:model post"

      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
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
    context "when model is configured with has_logidze(ignore_log_data: true)" do
      context "with default scope" do
        subject { NotLoggedPost.find(post.id) }

        it "loads data from DB" do
          expect(subject.reload_log_data).not_to be_nil
          expect(subject.reload_log_data).to be_a(Logidze::History)
        end
      end

      context ".with_log_data" do
        subject { NotLoggedPost.with_log_data.find(post.id) }

        it "loads log_data" do
          expect(subject.log_data).not_to be_nil
          expect(subject.log_data).to be_a(Logidze::History)
        end
      end

      context "when model has default_scope with joined logidzed model" do
        subject { NotLoggedPost::WithDefaultScope.with_log_data.find(post.id) }

        it "returns log_data" do
          expect(subject.reload_log_data).to be_a(Logidze::History)
        end
      end

      describe ".eager_load" do
        subject(:model) { User.eager_load(:not_logged_posts).last.not_logged_posts.last }

        it "loads data from DB" do
          expect(subject.reload_log_data).not_to be_nil
          expect(subject.reload_log_data).to be_a(Logidze::History)
        end
      end
    end
  end
end
