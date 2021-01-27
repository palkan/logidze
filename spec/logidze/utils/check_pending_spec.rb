# frozen_string_literal: true

require "spec_helper"
require "logidze/utils/check_pending"

describe Logidze::Utils::CheckPending do
  subject { described_class.new(app) }

  before(:each) do
    allow(Logidze::Utils::FunctionDefinitions).to receive(:from_fs).and_return(from_fs_result)
    allow(Logidze::Utils::FunctionDefinitions).to receive(:from_db).and_return(from_db_result)
  end

  let(:app) { ->(_) {} }
  let(:env) { [] }
  let(:from_fs_result) { [] }
  let(:from_db_result) { [] }

  context "when functions are up to date" do
    let(:from_fs_result) { [] }
    let(:from_db_result) { from_fs_result }

    it "does not warn or raise" do
      expect { subject.call(env) }.not_to output.to_stderr
      expect { subject.call(env) }.not_to raise_error
    end

    it "does not check functions next time" do
      subject.call(env)
      subject.call(env)

      expect(Logidze::Utils::FunctionDefinitions)
        .to have_received(:from_fs).once
      expect(Logidze::Utils::FunctionDefinitions)
        .to have_received(:from_db).once
    end
  end

  context "when functions are outdated" do
    let(:from_fs_result) { [Logidze::Utils::FuncDef.new(name: "func", version: 1)] }
    let(:from_db_result) { [] }

    context "when :warn option is set" do
      before(:all) { Logidze.on_pending_upgrade = :warn }
      after(:all) { Logidze.on_pending_upgrade = :ignore }

      it "prints warning" do
        expected_message = "Logidze needs upgrade. Run `bundle exec rails generate logidze:install --update`\n"
        expect { subject.call(env) }.to output(expected_message).to_stderr
      end

      it "does not check functions next time" do
        subject.call(env)
        subject.call(env)

        expect(Logidze::Utils::FunctionDefinitions)
          .to have_received(:from_fs).once
        expect(Logidze::Utils::FunctionDefinitions)
          .to have_received(:from_db).once
      end
    end

    context "when :raise option is set" do
      before(:all) { Logidze.on_pending_upgrade = :raise }
      after(:all) { Logidze.on_pending_upgrade = :ignore }

      it "raises an error" do
        expect { subject.call(env) }.to raise_error(Logidze::Utils::PendingMigrationError)
      end

      it "checks functions next time" do
        expect { subject.call(env) }.to raise_error(Logidze::Utils::PendingMigrationError)
        expect { subject.call(env) }.to raise_error(Logidze::Utils::PendingMigrationError)

        expect(Logidze::Utils::FunctionDefinitions)
          .to have_received(:from_fs).once
        expect(Logidze::Utils::FunctionDefinitions)
          .to have_received(:from_db).twice
      end
    end
  end
end
