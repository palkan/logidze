# frozen_string_literal: true

require "spec_helper"
require "generators/logidze/model/model_generator"

describe Logidze::Generators::ModelGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  before do
    prepare_destination
    FileUtils.mkdir_p(File.dirname(path))
  end

  after { FileUtils.rm(path) }

  describe "migration" do
    context "without namespace" do
      subject { migration_file("db/migrate/add_logidze_to_users.rb") }

      let(:path) { File.join(destination_root, "app", "models", "user.rb") }
      let(:args) { ["user"] }

      before do
        File.write(
          path,
          <<~RAW
            class User < ActiveRecord::Base
            end
          RAW
        )
        run_generator(args)
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "add_column :users, :log_data, :jsonb"
        is_expected.to contain(/create trigger logidze_on_users/i)
        is_expected.to contain(/before update or insert on users for each row/i)
        is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at'\);/i)
        is_expected.to contain(/drop trigger if exists logidze_on_users on users/i)
        is_expected.to contain "remove_column :users, :log_data"
        is_expected.not_to contain(/update users/i)

        expect(file("app/models/user.rb")).to contain "has_logidze"
      end

      context "with limit" do
        let(:args) { ["user", "--limit=5"] }

        it "creates trigger with limit" do
          is_expected.to exist
          is_expected.to contain(/execute procedure logidze_logger\(5, 'updated_at'\);/i)
        end
      end

      context "with debounce_time" do
        let(:args) { ["user", "--debounce_time=5000"] }

        it "creates trigger with debounce_time" do
          is_expected.to exist
          is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at', null, 5000\);/i)
        end
      end

      context "with columns blacklist" do
        let(:args) { ["user", "--blacklist", "age", "active"] }

        it "creates trigger with columns blacklist" do
          is_expected.to exist
          is_expected.to contain(
            /execute procedure logidze_logger\(null, 'updated_at', '\{age, active\}'\);/i
          )
        end
      end

      context "with backfill" do
        let(:args) { ["user", "--backfill"] }

        it "creates backfill query" do
          is_expected.to exist
          is_expected.to contain(/update users as t/i)
          is_expected.to contain(/set log_data = logidze_snapshot\(to_jsonb\(t\), 'updated_at'\);/i)
        end
      end

      context "with only trigger" do
        let(:args) { ["user", "--only-trigger"] }

        it "creates migration with trigger" do
          is_expected.to exist
          is_expected.not_to contain "add_column :users, :log_data, :jsonb"
          is_expected.to contain(/create trigger logidze_on_users/i)
          is_expected.to contain(/before update or insert on users for each row/i)
          is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at'\);/i)
          is_expected.to contain(/drop trigger if exists logidze_on_users on users/i)
          is_expected.not_to contain "remove_column :users, :log_data"
        end
      end

      context "when update" do
        subject { migration_file("db/migrate/update_logidze_for_users.rb") }

        let(:args) { ["user", "--update"] }

        it "creates migration with drop and create trigger" do
          is_expected.to exist
          is_expected.not_to contain "add_column :users, :log_data, :jsonb"
          is_expected.to contain(/drop trigger logidze_on_users/i)
          is_expected.to contain(/before update or insert on users for each row/i)
          is_expected.to contain "raise ActiveRecord::IrreversibleMigration"
          is_expected.not_to contain(/drop trigger if exists logidze_on_users on users/i)
          is_expected.not_to contain "remove_column :users, :log_data"
        end
      end

      context "with timestamp_column" do
        context "custom column name" do
          let(:args) { ["user", "--timestamp_column", "time"] }

          it "creates trigger with 'time' timestamp column" do
            is_expected.to exist
            is_expected.to contain(
              /execute procedure logidze_logger\(null, 'time'\);/i
            )
          end
        end

        context "nil" do
          let(:args) { ["user", "--timestamp_column", "nil"] }

          it "creates trigger without timestamp column" do
            is_expected.to exist
            is_expected.to contain(
              /execute procedure logidze_logger\(\);/i
            )
          end
        end
      end
    end

    context "with namespace" do
      subject { migration_file("db/migrate/add_logidze_to_user_guests.rb") }

      let(:path) { File.join(destination_root, "app", "models", "user", "guest.rb") }

      before do
        File.write(
          path,
          <<~RAW
            module User
              class Guest < ActiveRecord::Base
              end
            end
          RAW
        )
        run_generator ["User/Guest"]
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "add_column :user_guests, :log_data, :jsonb"

        expect(file("app/models/user/guest.rb")).to contain "has_logidze"
      end
    end

    context "with custom path" do
      subject { migration_file("db/migrate/add_logidze_to_data_sets.rb") }

      let(:path) { File.join(destination_root, "app", "models", "custom", "data", "set.rb") }

      before do
        File.write(
          path,
          <<~RAW
            module Data
              class Set < ActiveRecord::Base
              end
            end
          RAW
        )
        run_generator ["data/set", "--path", "app/models/custom/data/set.rb"]
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "add_column :data_sets, :log_data, :jsonb"

        expect(file("app/models/custom/data/set.rb")).to contain "has_logidze"
      end
    end
  end
end
