require 'spec_helper'
require 'generators/logidze/install/install_generator'

describe Logidze::Generators::InstallGenerator, type: :generator do
  destination File.expand_path("../../../tmp", __FILE__)

  before do
    prepare_destination
    run_generator
  end

  subject { migration_file('db/migrate/logidze_install.rb') }

  describe "migration" do
    it { is_expected.to exist }
    it { is_expected.to contain /create or replace function logidze_logger/i }
  end
end
