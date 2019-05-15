# frozen_string_literal: true

require "acceptance_helper"

describe "Logidze meta", :db do
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

  let(:meta) { {"some_key" => "some_val"} }
  let(:meta_alt) { {"some_key" => "some_val2"} }
  let(:meta2) { {"other_key" => "other_val"} }

  describe ".with_meta" do
    subject { User.create!(name: "test", age: 10, active: false) }

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
              begin
                Logidze.with_meta(meta2) do
                  expect(Thread.current[:meta]).to eq([meta, meta2])
                  raise "error inside the nested block"
                end
              ensure
                expect(Thread.current[:meta]).to eq([meta])
              end
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
end
