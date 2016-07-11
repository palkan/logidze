# frozen_string_literal: true
require "acceptance_helper"

describe "Logidze responsibility", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"
      successfully "rails generate logidze:model user --only-trigger --limit=5"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  describe ".with_responsible" do
    let(:responsible) { User.create!(name: 'owner') }

    subject { User.create!(name: 'test', age: 10, active: false) }

    context "insert" do
      it "doesn't set responsible user if it's not provided" do
        expect(subject.reload.whodunnit).to be_nil
      end

      it "loads responsible when id is provided" do
        Logidze.with_responsible(responsible.id) do
          expect(subject.reload.whodunnit).to eq responsible
        end
      end

      it "loads responsible when id is string" do
        Logidze.with_responsible(responsible.name) do
          expect(subject.reload.becomes(CustomUser).whodunnit).to eq responsible
        end
      end

      it "handles failed transaction" do
        ignore_exceptions do
          Logidze.with_responsible(responsible.id) do
            CustomUser.create!
          end
        end

        expect(subject.reload.whodunnit).to be_nil
      end

      it "handles block" do
        block = -> { subject }

        Logidze.with_responsible(responsible.id, &block)

        expect(subject.reload.whodunnit).to eq responsible
      end

      it "handles nil" do
        block = -> { subject }

        Logidze.with_responsible(nil, &block)

        expect(subject.reload.whodunnit).to be_nil
        expect(subject.log_data.current_version.data.keys).not_to include(Logidze::History::Version::RESPONSIBLE)
      end
    end

    context "update" do
      let(:responsible2) { User.create!(name: 'tester') }

      it "sets responsible" do
        Logidze.with_responsible(responsible.id) do
          subject.update!(age: 12)
        end

        expect(subject.reload.whodunnit).to eq responsible
      end

      it "works with undo/redo" do
        Logidze.with_responsible(responsible.id) do
          subject.update!(age: 12)
        end

        subject.update!(active: true)

        Logidze.with_responsible(responsible2.id) do
          subject.update!(name: 'updated')
        end

        expect(subject.reload.whodunnit).to eq responsible2
        subject.undo!

        expect(subject.reload.whodunnit).to be_nil
        subject.redo!

        expect(subject.reload.whodunnit).to eq responsible2
        subject.switch_to!(2)

        expect(subject.reload.whodunnit).to eq responsible
      end

      it "handles history compaction" do
        # 2 vesions (insert + update)
        Logidze.with_responsible(responsible.id) do
          subject.update!(age: 12)
        end

        expect(subject.reload.log_size).to eq 2

        Logidze.with_responsible(responsible2.id) do
          # version 3
          subject.update!(active: true)
          # version 4
          subject.update!(name: 'updated')
          # version 5
          subject.update!(age: 100)
        end

        subject.update!(name: 'compacted')

        expect(subject.reload.log_size).to eq 5

        # now the second version is the earliest
        expect(subject.at_version(1)).to be_nil
        expect(subject.at_version(2).whodunnit).to eq responsible

        subject.update!(age: 27)

        expect(subject.reload.log_size).to eq 5

        # now the third version is the earliest
        expect(subject.at_version(2)).to be_nil
        expect(subject.at_version(3).whodunnit).to eq responsible2
      end
    end
  end
end
