# frozen_string_literal: true

require "spec_helper"
require "generators/logidze/migration/logs_generator"

describe Logidze::Generators::Migration::LogsGenerator, type: :generator do
  destination File.expand_path("../../tmp", __dir__)

  let(:ar_version) { "6.0" }

  before do
    prepare_destination
    allow(ActiveRecord::Migration).to receive(:current_version).and_return(ar_version)
  end

  describe "migration" do
    subject { migration_file("db/migrate/create_logidze_data.rb") }

    it "creates migration" do
      run_generator

      is_expected.to be_a_file
      is_expected.to contain "ActiveRecord::Migration[#{ar_version}]"
      is_expected.to contain "create_table :logidze_data"
      is_expected.to contain "t.jsonb :log_data"
      is_expected.to contain "t.belongs_to :loggable, polymorphic: true"
      is_expected.to contain "t.timestamps"
    end
  end
end
