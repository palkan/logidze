# frozen_string_literal: true

require "spec_helper"
require "generators/logidze/model/model_generator"

describe Logidze::Generators::ModelGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  let(:use_fx_args) { USE_FX ? [] : ["--fx"] }
  let(:fx_args) { USE_FX ? ["--no-fx"] : [] }

  let(:table_name_prefix) { TABLE_NAME_PREFIX }
  let(:table_name_suffix) { TABLE_NAME_SUFFIX }

  let(:full_table_name) {
    ->(table_name) {
      "#{table_name_prefix}#{table_name}#{table_name_suffix}"
    }
  }

  let(:base_args) { [] }
  let(:args) { base_args + fx_args }
  let(:ar_version) { "6.0" }

  before do
    prepare_destination
    FileUtils.mkdir_p(File.dirname(path))
    allow(ActiveRecord::Migration).to receive(:current_version).and_return(ar_version)
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
            class User < ActiveRecord::Base
            end
          RAW
        )
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "ActiveRecord::Migration[#{ar_version}]"
        is_expected.to contain "add_column :users, :log_data, :jsonb"
        is_expected.to contain(/create trigger "logidze_on_#{full_table_name['users']}"/i)
        is_expected.to contain(/before update or insert on "#{full_table_name['users']}" for each row/i)
        is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at'\);/i)
        is_expected.to contain(/drop trigger if exists \\\"logidze_on_#{full_table_name['users']}\\\" on \\\"#{full_table_name['users']}\\\"/i)
        is_expected.not_to contain(/update \\\"#{full_table_name['users']}\\\"/i)

        expect(file("app/models/user.rb")).to contain "has_logidze"
      end

      context "with fx" do
        let(:fx_args) { use_fx_args }

        it "creates migration", :aggregate_failures do
          is_expected.to exist
          is_expected.to contain("create_trigger :logidze_on_users, on: :users")
        end

        it "creates a trigger file" do
          is_expected.to exist
          expect(file("db/triggers/logidze_on_users_v01.sql")).to exist
        end
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
          is_expected.to contain(/update \"#{full_table_name['users']}\" as t/i)
          is_expected.to contain(/set log_data = logidze_snapshot\(to_jsonb\(t\), 'updated_at'\);/i)
        end
      end

      context "with only trigger" do
        let(:base_args) { ["user", "--only-trigger"] }

        it "creates migration with trigger" do
          is_expected.to exist
          is_expected.not_to contain "add_column :users, :log_data, :jsonb"
          is_expected.to contain(/create trigger "logidze_on_#{full_table_name['users']}"/i)
          is_expected.to contain(/before update or insert on "#{full_table_name['users']}" for each row/i)
          is_expected.to contain(/execute procedure logidze_logger\(null, 'updated_at'\);/i)
          is_expected.to contain(/drop trigger if exists \\\"logidze_on_#{full_table_name['users']}\\\" on \\\"#{full_table_name['users']}\\\"/i)
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
          is_expected.to contain(/drop trigger if exists \\\"logidze_on_#{full_table_name['users']}\\\" on \\\"#{full_table_name['users']}\\\"/i)
          is_expected.to contain(/before update or insert on "#{full_table_name['users']}" for each row/i)
          is_expected.to contain "raise ActiveRecord::IrreversibleMigration"
        end

        context "with fx" do
          let(:fx_args) { use_fx_args }

          before do
            FileUtils.mkdir_p(file("db/triggers"))
            File.write(file("db/triggers/logidze_on_users_v01.sql"), "")
          end

          after do
            File.delete(file("db/triggers/logidze_on_users_v01.sql"))
            FileUtils.rm_r(file("db/triggers"))
          end

          it "creates migration", :aggregate_failures do
            is_expected.to exist
            is_expected.to contain("update_trigger :logidze_on_users, on: :users, version: 2, revert_to_version: 1")
          end

          it "creates a trigger file" do
            is_expected.to exist
            expect(file("db/triggers/logidze_on_users_v02.sql")).to exist
          end
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
              class Guest < ActiveRecord::Base
              end
            end
          RAW
        )
        run_generator(args)
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

      let(:base_args) { ["data/set", "--path", "app/models/custom/data/set.rb"] }

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
        run_generator(args)
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "add_column :data_sets, :log_data, :jsonb"

        expect(file("app/models/custom/data/set.rb")).to contain "has_logidze"
      end
    end
  end
end
