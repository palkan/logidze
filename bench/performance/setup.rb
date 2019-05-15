# frozen_string_literal: true

begin
  require "bundler/inline"
rescue LoadError => e
  warn "Bundler version 1.10 or later is required. Please update your Bundler"
  raise e
end

gemfile(true) do
  source "https://rubygems.org"
  gem "activerecord", "~>4.2"
  gem "pg"
  gem "paper_trail", "~>4.2", require: false
  gem "pry-byebug"
  gem "faker"
  gem "benchmark-ips"
  gem "memory_profiler"
end

DB_NAME = ENV["DB_NAME"] || "logidze_query_bench"

begin
  system("createdb #{DB_NAME}")
rescue
  $stdout.puts "DB already exists"
end

$LOAD_PATH.unshift File.expand_path("../../../lib", __FILE__)

require "active_record"
require "logger"
require "logidze"

ActiveRecord::Base.send :include, Logidze::HasLogidze

ActiveRecord::Base.establish_connection(adapter: "postgresql", database: DB_NAME)

at_exit do
  ActiveRecord::Base.connection.disconnect!
end

require "paper_trail"

module LogidzeBench
  module_function

  def setup_db
    ActiveRecord::Schema.define do
      # PaperTrail setup
      create_table :versions, force: true do |t|
        t.string :item_type, null: false
        t.integer :item_id, null: false
        t.string :event, null: false
        t.string :whodunnit
        t.text :object
        t.jsonb :object_changes

        t.datetime :created_at
      end

      add_index :versions, [:item_type, :item_id]

      # Logidze setup
      enable_extension :hstore

      execute <<~SQL
        DO $$
          BEGIN
          EXECUTE 'ALTER DATABASE ' || current_database() || ' SET logidze.disabled TO off';
          END;
        $$
        LANGUAGE plpgsql;
      SQL

      execute <<~SQL
        CREATE OR REPLACE FUNCTION logidze_logger() RETURNS TRIGGER AS $body$
          DECLARE
            changes jsonb;
            new_v integer;
            ts bigint;
            size integer;
            history_limit integer;
            current_version integer;
            merged jsonb;
            iterator integer;
            item record;
          BEGIN
            ts := (extract(epoch from now()) * 1000)::bigint;

            IF TG_OP = 'INSERT' THEN
              changes := to_jsonb(NEW.*) - 'log_data';
              new_v := 1;

              NEW.log_data := json_build_object(
                'v',
                1,
                'h',
                jsonb_build_array(
                  jsonb_build_object(
                    'ts',
                    ts,
                    'v',
                    new_v,
                    'c',
                    changes
                  )
                )
              );
            ELSIF TG_OP = 'UPDATE' THEN
              history_limit := TG_ARGV[0];
              current_version := (NEW.log_data->>'v')::int;

              IF NEW = OLD THEN
                RETURN NEW;
              END IF;

              IF current_version < (NEW.log_data#>>'{h,-1,v}')::int THEN
                iterator := 0;
                FOR item in SELECT * FROM jsonb_array_elements(NEW.log_data->'h')
                LOOP
                  IF (item.value->>'v')::int > current_version THEN
                    NEW.log_data := jsonb_set(
                      NEW.log_data,
                      '{h}',
                      (NEW.log_data->'h') - iterator
                    );
                  END IF;
                  iterator := iterator + 1;
                END LOOP;
              END IF;

              changes := hstore_to_jsonb_loose(
                hstore(NEW.*) - hstore(OLD.*)
              ) - 'log_data';

              new_v := (NEW.log_data#>>'{h,-1,v}')::int + 1;

              size := jsonb_array_length(NEW.log_data->'h');

              NEW.log_data := jsonb_set(
                NEW.log_data,
                ARRAY['h', size::text],
                jsonb_build_object(
                  'ts',
                  ts,
                  'v',
                  new_v,
                  'c',
                  changes
                ),
                true
              );

              NEW.log_data := jsonb_set(
                NEW.log_data,
                '{v}',
                to_jsonb(new_v)
              );

              IF history_limit IS NOT NULL AND history_limit = size THEN
                merged := jsonb_build_object(
                  'ts',
                  NEW.log_data#>'{h,1,ts}',
                  'v',
                  NEW.log_data#>'{h,1,v}',
                  'c',
                  (NEW.log_data#>'{h,0,c}') || (NEW.log_data#>'{h,1,c}')
                );

                NEW.log_data := jsonb_set(
                  NEW.log_data,
                  '{h}',
                  jsonb_set(
                    NEW.log_data->'h',
                    '{1}',
                    merged
                  ) - 0
                );
              END IF;
            END IF;

            return NEW;
          END;
          $body$
          LANGUAGE plpgsql;
      SQL

      create_table :users, force: true do |t|
        t.string :email
        t.integer :position
        t.string :name
        t.text :bio
        t.integer :age
        t.timestamps
      end

      create_table :logidze_users, force: true do |t|
        t.string :email
        t.integer :position
        t.string :name
        t.text :bio
        t.integer :age
        t.jsonb :log_data, default: "{}", null: false
        t.timestamps
      end

      execute <<~SQL
        CREATE TRIGGER logidze_on_logidze_users
        BEFORE UPDATE OR INSERT ON logidze_users FOR EACH ROW
        WHEN (current_setting('logidze.disabled') <> 'on')
        EXECUTE PROCEDURE logidze_logger();
      SQL
    end
  end

  module_function

  def populate(n = 1_000)
    n.times do
      params = fake_params
      User.create!(params)
      LogidzeUser.create!(params)
    end
  end

  module_function

  def cleanup
    LogidzeUser.delete_all
    User.delete_all
    PaperTrail::Version.delete_all
  end

  module_function

  def generate_versions(num = 1)
    num.times do
      User.find_each do |u|
        u.update!(fake_params(sample: true))
      end

      LogidzeUser.find_each do |u|
        u.update!(fake_params(sample: true))
      end

      # make at least 1 second between versions
      sleep 1
    end
    Time.now
  end

  module_function

  def fake_params(sample: false)
    params = {
      email: Faker::Internet.email,
      position: Faker::Number.number(3),
      name: Faker::Name.name,
      age: Faker::Number.number(2),
      bio: Faker::Lorem.paragraph
    }

    return params.slice(%i[email position name age bio].sample) if sample
    params
  end
end

module ARandom
  def random(num = 1)
    rel = order("random()")
    num == 1 ? rel.first : rel.limit(num)
  end
end

class User < ActiveRecord::Base
  extend ARandom
  has_paper_trail

  def self.diff_from(ts)
    includes(:versions).map { |u| {"id" => u.id, "changes" => u.diff_from(ts)} }
  end

  def self.diff_from_joined(ts)
    eager_load(:versions).map { |u| {"id" => u.id, "changes" => u.diff_from(ts)} }
  end

  def diff_from(ts)
    changes = {}
    versions.each do |v|
      next if v.created_at < ts
      merge_changeset(changes, v.changeset)
    end
    changes
  end

  private

  def merge_changeset(acc, data)
    data.each do |k, v|
      unless acc.key?(k)
        acc[k] = {"old" => v[0]}
      end
      acc[k]["new"] = v[1]
    end
  end
end

class LogidzeUser < ActiveRecord::Base
  extend ARandom
  has_logidze
end

# Run migration only if neccessary
LogidzeBench.setup_db if ENV["FORCE"].present? || !ActiveRecord::Base.connection.tables.include?("logidze_users")
