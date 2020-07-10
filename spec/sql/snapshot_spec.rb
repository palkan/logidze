# frozen_string_literal: true

require "acceptance_helper"

describe "logidze_snapshot", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"

      migration "add_logidze_snapshot_trigger", <<~RUBY
        def up
          add_column :posts, :logidze_snapshot, :jsonb
          add_column :posts, :logidze_snapshot_without_params, :jsonb

          execute %q(
            CREATE OR REPLACE FUNCTION logidze_test_trigger() RETURNS TRIGGER AS $body$
              DECLARE
                list text[];
                filter_only bool;
                ts_column text;
              BEGIN
                ts_column := TG_ARGV[0];
                list := TG_ARGV[1];
                filter_only := TG_ARGV[2];

                NEW.logidze_snapshot := logidze_snapshot(to_jsonb(NEW.*), ts_column, list, filter_only);
                NEW.logidze_snapshot_without_params := logidze_snapshot(to_jsonb(NEW.*));
              RETURN NEW;
            END;
            $body$
            LANGUAGE plpgsql;
          )

          execute %q(
            CREATE TRIGGER logidze_test
            BEFORE UPDATE OR INSERT ON posts FOR EACH ROW
            EXECUTE PROCEDURE logidze_test_trigger('updated_at', '{title,rating}', true);
          )
        end

        def down
          execute "DROP FUNCTION logidze_test_trigger() CASCADE;"

          remove_column :posts, :logidze_snapshot
          remove_column :posts, :logidze_snapshot_without_params
        end
      RUBY

      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Post.reset_column_information
  end

  let(:now) { Time.local(1989, 7, 10, 18, 23, 33) }

  specify "with params" do
    post = Post.create!(title: "Feel me", rating: 42, meta: {some: "test"}, updated_at: now)

    snapshot = post.reload.logidze_snapshot

    expect(snapshot["v"]).to eq 1
    expect(snapshot["h"].size).to eq 1

    version = snapshot["h"].first

    expect(version).to match({
      "ts" => now.to_i * 1_000,
      "v" => 1,
      "c" => {"title" => "Feel me", "rating" => 42}
    })
  end

  specify "without params" do
    post = Post.create!(title: "Feel me", rating: 42, meta: {some: "test"}, updated_at: now)

    snapshot = post.reload.logidze_snapshot_without_params

    expect(snapshot["v"]).to eq 1
    expect(snapshot["h"].size).to eq 1

    version = snapshot["h"].first

    expect(version).to match({
      "ts" => an_instance_of(Integer),
      "v" => 1,
      "c" => a_hash_including({"title" => "Feel me", "rating" => 42, "active" => nil, "user_id" => nil})
    })

    expect(Time.at(version["ts"]) - now).to be > 1.year
  end
end
