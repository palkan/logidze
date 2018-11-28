# frozen_string_literal: true
require "spec_helper"
require "acceptance_helper"

describe Logidze::IgnoreLogData, :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"
      successfully "rails generate logidze:model post"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
    # For Rails 4
    Post.instance_variable_set(:@attribute_names, nil)
  end

  let(:user) { User.create! }
  let!(:source_post) { Post.create!(user: user) }

  shared_context "test #log_data" do
    context "#log_data" do
      it "raises error when log_data is called" do
        expect { post.log_data }.to raise_error(ActiveModel::MissingAttributeError)
      end
    end
  end

  shared_context "test #reload_log_data" do
    context "#reload_log_data" do
      it "loads data from DB" do
        expect(post.reload_log_data).not_to be_nil
        expect(post.log_data).not_to be_nil
      end

      it "deserializes log_data properly" do
        expect(post.reload_log_data).to be_a(Logidze::History)
      end
    end
  end

  context "with .all" do
    subject(:post) { NotLoggedPost.find(source_post.id) }

    include_context "test #log_data"
    include_context "test #reload_log_data"
  end

  context "with .with_log_data" do
    subject(:post) { NotLoggedPost.with_log_data.find(source_post.id) }

    context "#log_data" do
      it "loads log_data" do
        expect(post.log_data).not_to be_nil
      end

      it "deserializes log_data properly" do
        expect(post.log_data).to be_a(Logidze::History)
      end
    end
  end

  context "#update!" do
    it "updates log_data" do
      expect do
        NotLoggedPost.find(source_post.id).update!(title: "new")
      end.to change { Post.find(source_post.id).log_data.version }.by(1)
    end
  end

  context "with .eager_load" do
    subject(:post) { User.eager_load(:not_logged_posts).last.not_logged_posts.last }

    include_context "test #log_data"
    include_context "test #reload_log_data"
  end
end
