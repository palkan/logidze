require 'spec_helper'
require 'generators/logidze/install/install_generator'

describe Logidze::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../../tmp", __FILE__)

  before do
    prepare_destination
    run_generator
  end

  describe "trigger migration" do
    subject { migration_file('db/migrate/logidze_install.rb') }

    it "creates migration", :aggregate_failures do
      is_expected.to exist
      is_expected.to contain /create or replace function logidze_logger/i
    end
  end

  describe "hstore migration" do
    subject { migration_file('db/migrate/enable_hstore.rb') }

    it "creates migration", :aggregate_failures do
      is_expected.to exist
      is_expected.to contain /enable_extension :hstore/i
    end
  end
end
