# frozen_string_literal: true

require "generators/logidze/model/model_generator"

describe Logidze::Generators::ModelGenerator, type: :generator, sequel: true do
  destination File.expand_path("../../../tmp", __dir__)

  let(:base_args) { [] }
  let(:sequel_args) { ["--sequel"] }
  let(:args) { base_args + sequel_args }

  before do
    prepare_destination
    FileUtils.mkdir_p(File.dirname(path))
  end

  after { FileUtils.rm(path) }

  describe "migration" do
    context "without namespace" do
      subject do
        run_generator(args)
        migration_file("db/migrate/add_logidze_to_users.rb")
      end

      let(:path) { File.join(destination_root, "app", "models", "user.rb") }
      let(:base_args) { ["user"] }

      before do
        File.write(
          path,
          <<~RAW
            class User < Sequel::Model
            end
          RAW
        )
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "Sequel.migration"
        is_expected.to contain "up do"
        is_expected.to contain "add_column :users, :log_data, :jsonb"
        is_expected.to contain(/create trigger "logidze_on_users"/i)
        is_expected.to contain(/before update or insert on "users" for each row/i)
        is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at'\);/i)
        is_expected.to contain "down do"
        is_expected.to contain(/drop trigger if exists "logidze_on_users" on "users"/i)
        is_expected.not_to contain(/update "users"/i)

        expect(file("app/models/user.rb")).to contain "plugin :logidze"
      end

      context "with limit" do
        let(:base_args) { ["user", "--limit=5"] }

        it "creates trigger with limit" do
          is_expected.to exist
          is_expected.to contain(/execute procedure logidze_logger\(5, 'updated_at'\);/i)
        end
      end

      context "with debounce_time" do
        let(:base_args) { ["user", "--debounce_time=5000"] }

        it "creates trigger with debounce_time" do
          is_expected.to exist
          is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at', null, null, 5000\);/i)
        end
      end

      context "with except" do
        let(:base_args) { ["user", "--except", "age", "active"] }

        it "creates trigger with columns exclusion" do
          is_expected.to exist
          is_expected.to contain(
            /execute procedure logidze_logger\(null, 'updated_at', '\{age, active\}'\);/i
          )
        end
      end

      context "with only" do
        let(:base_args) { ["user", "--only", "age", "active"] }

        it "creates trigger with columns inclusion" do
          is_expected.to exist
          is_expected.to contain(
            /execute procedure logidze_logger\(null, 'updated_at', '\{age, active\}', true\);/i
          )
        end
      end

      context "with backfill" do
        let(:base_args) { ["user", "--backfill"] }

        it "creates backfill query" do
          is_expected.to exist
          is_expected.to contain(/update "users" as t/i)
          is_expected.to contain(/set log_data = logidze_snapshot\(to_jsonb\(t\), 'updated_at'\);/i)
        end
      end

      context "with only trigger" do
        let(:base_args) { ["user", "--only-trigger"] }

        it "creates migration with trigger" do
          is_expected.to exist
          is_expected.not_to contain "add_column :users, :log_data, :jsonb"
          is_expected.to contain(/create trigger "logidze_on_users"/i)
          is_expected.to contain(/before update or insert on "users" for each row/i)
          is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at'\);/i)
          is_expected.to contain(/drop trigger if exists "logidze_on_users" on "users"/i)
          is_expected.not_to contain "remove_column :users, :log_data"
        end
      end

      context "when update" do
        subject do
          run_generator(args)
          migration_file("db/migrate/update_logidze_for_users.rb")
        end

        let(:base_args) { ["user", "--update"] }

        it "creates migration with drop and create trigger" do
          is_expected.to exist
          is_expected.not_to contain "add_column :users, :log_data, :jsonb"
          is_expected.to contain(/drop trigger if exists "logidze_on_users" on "users"/i)
          is_expected.to contain(/before update or insert on "users" for each row/i)
          is_expected.to contain "raise Sequel::Error"
        end

        context "with custom name" do
          subject { migration_file("db/migrate/logidzedize_users.rb") }

          let(:base_args) { ["user", "--name", "logidzedize_users"] }

          before do
            run_generator(args)
          end

          it "creates migration", :aggregate_failures do
            is_expected.to exist
            is_expected.to contain "add_column :users, :log_data, :jsonb"
          end
        end
      end

      context "with timestamp_column" do
        context "custom column name" do
          let(:base_args) { ["user", "--timestamp_column", "time"] }

          it "creates trigger with 'time' timestamp column" do
            is_expected.to exist
            is_expected.to contain(
              /execute procedure logidze_logger\(null, 'time'\);/i
            )
          end
        end

        context "nil" do
          let(:base_args) { ["user", "--timestamp_column", "nil"] }

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

      let(:base_args) { ["User/Guest"] }

      before do
        File.write(
          path,
          <<~RAW
            module User
              class Guest < Sequel::Model(:users)
              end
            end
          RAW
        )
        run_generator(args)
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "add_column :user_guests, :log_data, :jsonb"

        expect(file("app/models/user/guest.rb")).to contain "plugin :logidze"
      end
    end

    context "with custom path" do
      subject { migration_file("db/migrate/add_logidze_to_data_sets.rb") }

      let(:path) { File.join(destination_root, "app", "models", "custom", "data", "set.rb") }

      let(:base_args) { ["data/set", "--path", "app/models/custom/data/set.rb"] }

      before do
        File.write(
          path,
          <<~RAW
            module Data
              class Set < Sequel::Model
              end
            end
          RAW
        )
        run_generator(args)
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "add_column :data_sets, :log_data, :jsonb"

        expect(file("app/models/custom/data/set.rb")).to contain "plugin :logidze"
      end
    end

    context "when revoking" do
      let(:path) { File.join(destination_root, "app", "models", "user.rb") }

      before do
        File.write(
          path,
          <<~RAW
            class User < Sequel::Model
            end
          RAW
        )
      end

      let(:path) { File.join(destination_root, "app", "models", "user.rb") }
      let(:base_args) { ["User"] }

      it "deletes migration file it created" do
        run_generator(args)
        migration_file = migration_file("db/migrate/add_logidze_to_users.rb")
        expect(migration_file).to exist

        Rails::Generators.invoke "logidze:model", args, behavior: :revoke, destination_root: destination_root
        migration_file = migration_file("db/migrate/add_logidze_to_users.rb")
        expect(migration_file).not_to exist
      end
    end
  end
end
