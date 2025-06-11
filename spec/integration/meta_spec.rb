# frozen_string_literal: true

require "acceptance_helper"

describe "logs metadata", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:model user --only-trigger --limit=5"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  let(:meta) { {"some_key" => "some_val"} }
  let(:meta_alt) { {"some_key" => "some_val2"} }
  let(:meta2) { {"other_key" => "other_val"} }

  describe ".with_meta" do
    subject(:user) { User.create!(name: "test", age: 10, active: false) }

    context "insert" do
      it "doesn't set meta if it's not provided" do
        expect(subject.reload.meta).to be_nil
      end

      it "loads meta when meta is provided" do
        Logidze.with_meta(meta) do
          expect(subject.reload.meta).to eq meta
        end
      end

      it "loads meta with stringified keys when hash with symbolized keys is provided" do
        Logidze.with_meta(meta.transform_keys(&:to_sym)) do
          expect(subject.reload.meta).to eq meta
        end
      end

      it "handles failed transaction" do
        ignore_exceptions do
          Logidze.with_meta(meta) do
            CustomUser.create!
          end
        end

        expect(subject.reload.meta).to be_nil
      end

      it "handles block" do
        block = -> { subject }

        Logidze.with_meta(meta, &block)

        expect(subject.reload.meta).to eq(meta)
      end

      it "handles nil" do
        block = -> { subject }

        Logidze.with_meta(nil, &block)

        expect(subject.reload.meta).to be_nil
        expect(subject.log_data.current_version.data.keys).not_to include(Logidze::History::Version::META)
      end

      it "handles nested blocks" do
        Logidze.with_meta(meta) do
          expect(Thread.current[:meta]).to eq([meta])

          Logidze.with_meta(meta2) do
            expect(Thread.current[:meta]).to eq([meta, meta2])
            expect(subject.reload.meta).to eq(meta.merge(meta2))
          end

          expect(Thread.current[:meta]).to eq([meta])
        end
      end

      it "overrides keys in nested blocks" do
        Logidze.with_meta(meta) do
          expect(Thread.current[:meta]).to eq([meta])

          Logidze.with_meta(meta_alt) do
            expect(Thread.current[:meta]).to eq([meta, meta_alt])
            expect(subject.reload.meta).to eq(meta_alt)
          end

          expect(Thread.current[:meta]).to eq([meta])
        end
      end

      it "cleans up meta storage after the exception" do
        expect do
          Logidze.with_meta(meta) do
            expect(Thread.current[:meta]).to eq([meta])

            expect do
              Logidze.with_meta(meta2) do
                expect(Thread.current[:meta]).to eq([meta, meta2])
                raise "error inside the nested block"
              end
            ensure
              expect(Thread.current[:meta]).to eq([meta])
            end.to raise_error(/error inside the nested block/)

            raise "error inside the block"
          end
        end.to raise_error(/error inside the block/)

        expect(Thread.current[:meta]).to eq([])
      end
    end

    context "update" do
      it "sets meta" do
        Logidze.with_meta(meta) do
          subject.update!(age: 12)
        end

        expect(subject.reload.meta).to eq(meta)
      end

      it "supports nested blocks" do
        Logidze.with_meta(meta) do
          subject.update!(age: 11)
          expect(subject.reload.meta).to eq(meta)

          Logidze.with_meta(meta2) do
            subject.update!(age: 12)
            expect(subject.reload.meta).to eq(meta.merge(meta2))
          end

          subject.update!(age: 13)
          expect(subject.reload.meta).to eq(meta)
        end
      end

      it "properly overrides keys inside nested blocks" do
        Logidze.with_meta(meta) do
          subject.update!(age: 11)
          expect(subject.reload.meta).to eq(meta)

          Logidze.with_meta(meta_alt) do
            subject.update!(age: 12)
            expect(subject.reload.meta).to eq(meta_alt)
          end

          subject.update!(age: 13)
          expect(subject.reload.meta).to eq(meta)
        end
      end

      it "works with undo/redo" do
        Logidze.with_meta(meta) do
          subject.update!(age: 12)
        end

        subject.update!(active: true)

        Logidze.with_meta(meta2) do
          subject.update!(name: "updated")
        end

        expect(subject.reload.meta).to eq meta2
        subject.undo!

        expect(subject.reload.meta).to be_nil
        subject.redo!

        expect(subject.reload.meta).to eq meta2
        subject.switch_to!(2)

        expect(subject.reload.meta).to eq meta
      end

      it "handles history compaction" do
        # 2 vesions (insert + update)
        Logidze.with_meta(meta) do
          subject.update!(age: 12)
        end

        expect(subject.reload.log_size).to eq 2

        Logidze.with_meta(meta2) do
          # version 3
          subject.update!(active: true)
          # version 4
          subject.update!(name: "updated")
          # version 5
          subject.update!(age: 100)
        end

        subject.update!(name: "compacted")

        expect(subject.reload.log_size).to eq 5

        # now the second version is the earliest
        expect(subject.at_version(1)).to be_nil
        expect(subject.at_version(2).meta).to eq meta

        subject.update!(age: 27)

        expect(subject.reload.log_size).to eq 5

        # now the third version is the earliest
        expect(subject.at_version(2)).to be_nil
        expect(subject.at_version(3).meta).to eq meta2
      end

      # See https://github.com/palkan/logidze/issues/236
      context "with Rails touch:true" do
        let!(:article) { Article.create!(title: "test", user: user) }

        it "updating a record updates the parent record's log_data with the correct meta" do
          Logidze.with_meta(meta, transactional: false) do
            article.touch(time: 1.minute.since)
          end

          expect(user.reload.log_data.meta).to eq(meta)
        end
      end
    end

    context "when transactional:false" do
      it "resets meta setting after block finishes" do
        # subject is a newly created user
        Logidze.with_meta(meta, transactional: false) do
          expect(subject.reload.meta).to eq meta
        end

        # create another one and check that meta is nil here
        expect(User.create!(name: "test", age: 10, active: false).reload.meta).to be_nil
      end

      it "recovers after exception" do
        ignore_exceptions do
          Logidze.with_meta(meta, transactional: false) do
            CustomUser.create!
          end
        end

        expect(subject.reload.meta).to be_nil
      end
    end
  end

  describe ".with_responsible" do
    let(:responsible) { User.create!(name: "owner") }

    subject { User.create!(name: "test", age: 10, active: false) }

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
        expect(subject.log_data.current_version.data.keys).not_to include(Logidze::History::Version::META)
      end

      it "handles nested blocks with responsible" do
        Logidze.with_responsible(responsible.id) do
          Logidze.with_meta(meta) do
            expect(subject.reload.meta).to eq meta.merge(
              Logidze::History::Version::META_RESPONSIBLE => responsible.id
            )
          end
        end
      end
    end

    context "update" do
      let(:responsible2) { User.create!(name: "tester") }

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
          subject.update!(name: "updated")
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
          subject.update!(name: "updated")
          # version 5
          subject.update!(age: 100)
        end

        subject.update!(name: "compacted")

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

  describe ".with_meta!" do
    subject { User.create!(name: "test", age: 10, active: false) }

    after { Logidze.clear_meta! }

    context "setting meta for connection" do
      it "sets meta for connection and persists across operations" do
        Logidze.with_meta!(meta)

        expect(subject.reload.meta).to eq(meta)
      end

      it "handles nil" do
        Logidze.with_meta!(nil)

        expect(subject.reload.meta).to be_nil
        expect(subject.log_data.current_version.data.keys).not_to include(Logidze::History::Version::META)
      end

      it "cannot be called inside block version" do
        Logidze.with_meta(meta) do
          expect { Logidze.with_meta!(meta2) }.to raise_error(StandardError, /cannot be called from within a with_meta block/)
        end
      end
    end
  end

  describe ".with_responsible!" do
    let(:responsible) { User.create!(name: "owner") }

    subject { User.create!(name: "test", age: 10, active: false) }

    after { Logidze.clear_meta! }

    context "setting responsible for connection" do
      it "sets responsible for connection and persists across operations" do
        Logidze.with_responsible!(responsible.id)

        expect(subject.reload.whodunnit).to eq(responsible)

        subject.update!(age: 11)
        expect(subject.reload.whodunnit).to eq(responsible)
      end

      it "handles nil responsible_id" do
        Logidze.with_responsible!(nil)

        expect(subject.reload.whodunnit).to be_nil
      end

      it "can be cleared with clear_meta!" do
        Logidze.with_responsible!(responsible.id)

        expect(subject.reload.whodunnit).to eq(responsible)

        Logidze.clear_meta!

        subject.update!(age: 12)
        expect(subject.reload.whodunnit).to be_nil
      end

      it "can be changed to a different responsible" do
        responsible2 = User.create!(name: "owner2")

        Logidze.with_responsible!(responsible.id)
        expect(subject.reload.whodunnit).to eq(responsible)

        Logidze.with_responsible!(responsible2.id)
        subject.update!(age: 11)
        expect(subject.reload.whodunnit).to eq(responsible2)
      end

      it "can add to existing metadata" do
        Logidze.with_meta!(meta)

        Logidze.with_responsible!(responsible.id)
        expect(subject.reload.whodunnit).to eq(responsible)
        expect(subject.meta).to eq(meta.merge(
          Logidze::History::Version::META_RESPONSIBLE => responsible.id
        ))
      end
    end
  end
end
