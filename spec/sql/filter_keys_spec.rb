# frozen_string_literal: true

require "acceptance_helper"

describe "logidze_filter_keys", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"

      migration "add_logidze_filter_columns_trigger", <<~RUBY
        def up
          add_column :posts, :filtered_only, :text
          add_column :posts, :filtered_except, :text

          execute %q(
            CREATE OR REPLACE FUNCTION logidze_test_trigger() RETURNS TRIGGER AS $body$
              DECLARE
                target_column text;
                list text[];
                filter_only bool;
              BEGIN
                list := TG_ARGV[0];
                target_column := TG_ARGV[1];
                filter_only := TG_ARGV[2];

                NEW := NEW #= hstore(target_column, logidze_filter_keys(to_jsonb(NEW.*), list, filter_only)::text);
              RETURN NEW;
            END;
            $body$
            LANGUAGE plpgsql;
          )

          execute %q(
            CREATE TRIGGER logidze_test_1
            BEFORE UPDATE OR INSERT ON posts FOR EACH ROW
            EXECUTE PROCEDURE logidze_test_trigger('{title,rating}', 'filtered_only', true);

            CREATE TRIGGER logidze_test_2
            BEFORE UPDATE OR INSERT ON posts FOR EACH ROW
            EXECUTE PROCEDURE logidze_test_trigger('{meta,created_at,updated_at}', 'filtered_except', false);
          )
        end

        def down
          execute "DROP FUNCTION logidze_test_trigger() CASCADE;"

          remove_column :posts, :filtered_except
          remove_column :posts, :filtered_only
        end
      RUBY

      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
  end

  specify "only filter" do
    post = Post.create!(title: "Feel me", rating: 42, meta: {some: "test"})
    expect(JSON.parse(post.reload.filtered_only)).to eq({"title" => "Feel me", "rating" => 42})
  end

  specify "except filter" do
    post = Post.create!(title: "Feel me", meta: {some: "test"})

    filtered = JSON.parse(post.reload.filtered_except)

    expect(filtered.keys).to include("id", "title", "active", "rating", "user_id")
    expect(filtered.keys).not_to include("meta", "created_at", "updated_at")
  end
end
