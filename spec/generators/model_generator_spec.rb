require 'spec_helper'
require 'generators/logidze/model/model_generator'

describe Logidze::Generators::ModelGenerator, type: :generator do
  destination File.expand_path("../../../tmp", __FILE__)

  before do
    prepare_destination
    FileUtils.mkdir_p(File.dirname(path))
  end

  after { FileUtils.rm(path) }

  describe "migration" do
    context "without namespace" do
      subject { migration_file('db/migrate/add_logidze_to_users.rb') }

      let(:path) { File.join(destination_root, "app", "models", "user.rb") }

      before do
        File.write(
          path,
          <<~RAW
            class User < ActiveRecord::Base
            end
            RAW
        )
        run_generator ["user"]
      end

      it "creates migration", :aggregate_failures do
        is_expected.to exist
        is_expected.to contain "add_column :users, :log_data, :jsonb, default: '{}', null: false"
        is_expected.to contain /create trigger logidze_on_users/i
        is_expected.to contain /before update or insert on users for each row/i
        is_expected.to contain /execute procedure logidze_logger\(\);/i
        is_expected.to contain /drop trigger if exists logidze_on_users on users/i
        is_expected.to contain "remove_column :users, :log_data"

        expect(file('app/models/user.rb')).to contain "has_logidze"
      end
    end

    context "with namespace" do
      subject { migration_file('db/migrate/add_logidze_to_user_guests.rb') }

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
        is_expected.to contain "add_column :user_guests, :log_data, :jsonb, default: '{}', null: false"

        expect(file('app/models/user/guest.rb')).to contain "has_logidze"
      end
    end
  end
end
