# frozen_string_literal: true

require "acceptance_helper"

describe "logidze_version", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"

      migration "add_logidze_version_trigger", <<~RUBY
        def up
          add_column :posts, :logidze_version, :jsonb

          execute %q(
            CREATE OR REPLACE FUNCTION logidze_test_trigger() RETURNS TRIGGER AS $body$
              BEGIN
                NEW.logidze_version := logidze_version(1, to_jsonb(NEW.*), statement_timestamp());
              RETURN NEW;
            END;
            $body$
            LANGUAGE plpgsql;
          )

          execute %q(
            CREATE TRIGGER logidze_test
            BEFORE UPDATE OR INSERT ON posts FOR EACH ROW
            EXECUTE PROCEDURE logidze_test_trigger();
          )
        end

        def down
          execute "DROP FUNCTION logidze_test_trigger() CASCADE;"

          remove_column :posts, :logidze_version
        end
      RUBY

      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
  end

  specify do
    post = Post.create!(title: "Feel me", rating: 42, meta: {some: "test"})
    version = post.reload.logidze_version
    expect(version).to match({
      "ts" => an_instance_of(Integer),
      "v" => 1,
      "c" => a_hash_including({"title" => "Feel me", "rating" => 42})
    })
  end

  specify "with meta" do
    post = Logidze.with_meta({cat: "matroskin"}) { Post.create!(title: "Feel me", meta: {some: "test"}) }

    version = post.reload.logidze_version
    expect(version).to match({
      "ts" => an_instance_of(Integer),
      "v" => 1,
      "c" => a_hash_including({"title" => "Feel me"}),
      "m" => {"cat" => "matroskin"}
    })
  end
end
