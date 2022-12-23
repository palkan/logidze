# frozen_string_literal: true

require "spec_helper"

describe Logidze::Model, :db do
  let(:user) do
    User.create!(
      name: "test",
      age: 10,
      active: false,
      log_data: {
        "v" => 5,
        "h" =>
          [
            {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil, "log_data" => nil}},
            {"v" => 2, "ts" => time(200), "c" => {"active" => true}},
            {"v" => 3, "ts" => time(200), "r" => 1, "c" => {"name" => "test"}, "m" => {"some_key" => "old_val"}},
            {"v" => 4, "ts" => time(300), "c" => {"age" => 0}},
            {"v" => 5, "ts" => time(400), "c" => {"age" => 10, "active" => false}, "m" => {"_r" => 2, "some_key" => "current_val"}}
          ]
      }
    )
  end

  describe "#at(time)" do
    it "returns version at specified time", :aggregate_failures do
      user_old = user.at(time: time(350))
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "returns nil if time is invalid (too early)" do
      expect(user.at(time: time(99))).to be_nil
    end

    it "returns self if actual version" do
      expect(user.at(time: time(401))).to be_equal(user)
    end

    it "returns self if log_data is nil" do
      user.log_data = nil
      expect(user.at(time: time(100))).to be_equal(user)
    end

    it "returns dup", :aggregate_failures do
      user_old = user.at(time: time(100))
      expect(user_old).not_to be_equal(user)

      user_old.age = 100
      expect(user.age).to eq 10
    end

    it "retains original object's id" do
      user_old = user.at(time: time(100))
      expect(user_old.id).to be_equal(user.id)
    end

    it "handles time as string", :aggregate_failures do
      user_old = user.at(time: "2016-04-12 12:05:50")
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "handles time as Time", :aggregate_failures do
      user_old = user.at(time: Time.new(2016, 0o4, 12, 12, 0o5, 50))
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "handles time as Date", :aggregate_failures do
      user_old = user.at(time: Date.new(2016, 0o4, 13))
      expect(user_old).to be_equal user
    end

    context "when Logidze.return_self_if_log_data_is_empty = false" do
      around do |ex|
        Logidze.return_self_if_log_data_is_empty = false
        ex.run
        Logidze.return_self_if_log_data_is_empty = true
      end

      it "returns nil if log_data is nil" do
        user.log_data = nil
        expect(user.at(time: time(100))).to be_nil
      end
    end
  end

  describe "#at(version)" do
    it "returns specified version", :aggregate_failures do
      user_old = user.at(version: 4)
      expect(user_old.name).to eq "test"
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end
  end

  describe "#at!" do
    it "update object in-place", :aggregate_failures do
      user.at!(time: time(350))

      expect(user.name).to eq "test"
      expect(user.age).to eq 0
      expect(user.active).to eq true

      expect(user.changes).to include("age" => [10, 0], "active" => [false, true])
    end

    it "raises ArgumentError if log_data is nil" do
      user.log_data = nil
      expect { user.at!(time: time(100)) }.to raise_error(ArgumentError)
    end
  end

  describe "#diff_from" do
    it "returns diff from specified time" do
      expect(user.diff_from(time: time(350)))
        .to eq(
          "id" => user.id,
          "changes" =>
            {
              "age" => {"old" => 0, "new" => 10},
              "active" => {"old" => true, "new" => false}
            }
        )
    end

    it "returns empty hash if log_data is nil" do
      user.log_data = nil
      expect(user.diff_from(time: time(350))).to eq({"id" => user.id, "changes" => {}})
    end
  end

  describe "undo!" do
    it "revert record to previous state", :aggregate_failures do
      expect(user.undo!).to eq true
      user.reload
      expect(user.name).to eq "test"
      expect(user.age).to eq 0
      expect(user.active).to eq true
    end

    it "revert record several times", :aggregate_failures do
      user.undo!
      expect(user.reload.age).to eq 0

      user.undo!
      expect(user.age).to be_nil

      user.undo!
      expect(user.name).to be_nil

      user.undo!
      user.reload

      expect(user.name).to be_nil
      expect(user.age).to be_nil
      expect(user.active).to be_nil
    end

    it "return false no possible undo" do
      u = User.create!(
        log_data: {
          "v" => 1,
          "h" =>
          [
            {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil}}
          ]
        }
      )

      expect(u.undo!).to eq false
    end
  end

  describe "redo!" do
    before do
      user.undo!
      user.reload
    end

    it "revert record to future state", :aggregate_failures do
      expect(user.redo!).to eq true
      user.reload
      expect(user.name).to eq "test"
      expect(user.age).to eq 10
      expect(user.active).to eq false
    end

    it "revert record several times", :aggregate_failures do
      user.undo!
      user.reload

      expect(user.name).to eq "test"
      expect(user.age).to be_nil
      expect(user.active).to eq true

      user.redo!
      user.redo!
      user.reload

      expect(user.name).to eq "test"
      expect(user.age).to eq 10
      expect(user.active).to eq false
    end

    it "return false no possible redo" do
      u = User.create!(
        log_data: {
          "v" => 1,
          "h" =>
          [
            {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil}}
          ]
        }
      )

      expect(u.redo!).to eq false
    end
  end

  describe "#switch_to!" do
    it "revert record to the specified version", :aggregate_failures do
      expect(user.switch_to!(3)).to eq true
      user.reload
      expect(user.log_version).to eq 3
      expect(user.name).to eq "test"
      expect(user.age).to be_nil
      expect(user.active).to eq true
    end

    it "return false if version is unknown" do
      expect(user.switch_to!(10)).to eq false
    end

    it "raises ArgumentError if log_data is nil" do
      user.log_data = nil
      expect { user.switch_to!(3) }.to raise_error(ArgumentError)
    end
  end

  describe ".at" do
    before { user }

    it "returns reverted records", :aggregate_failures do
      u = User.at(time: time(350)).first

      expect(u.name).to eq "test"
      expect(u.age).to eq 0
      expect(u.active).to eq true
    end

    it "returns reverted records when called on relation", :aggregate_failures do
      u = User.where(active: false).order(age: :desc).at(time: time(350)).first

      expect(u.name).to eq "test"
      expect(u.age).to eq 0
      expect(u.active).to eq true
    end

    it "skips nil records" do
      User.create!(
        log_data: {
          "v" => 1,
          "h" =>
            [
              {"v" => 1, "ts" => time(400), "c" => {"name" => nil, "age" => nil, "active" => nil}}
            ]
        }
      )

      expect(User.at(time: time(350)).size).to eq 1
    end
  end

  describe ".diff_from" do
    before { user }

    it "returns diffs for records", :aggregate_failures do
      expect(
        User.diff_from(time: time(350)).first
      ).to eq(
        "id" => user.id,
        "changes" =>
          {
            "age" => {"old" => 0, "new" => 10},
            "active" => {"old" => true, "new" => false}
          }
      )
    end

    it "returns diffs for records when called on relation", :aggregate_failures do
      expect(
        User.where(active: false).order(age: :desc).diff_from(time: time(350)).first
      ).to eq(
        "id" => user.id,
        "changes" =>
          {
            "age" => {"old" => 0, "new" => 10},
            "active" => {"old" => true, "new" => false}
          }
      )
    end
  end

  describe "#responsible_id" do
    it "returns id for current version" do
      expect(user.log_data.responsible_id).to eq 2
    end

    it "returns nil if no information" do
      expect(user.at(time: time(350)).log_data.responsible_id).to be_nil
    end

    it "returns id for previous version" do
      expect(user.at(time: time(250)).log_data.responsible_id).to eq 1
    end
  end

  describe "#meta" do
    it "returns meta for current version" do
      expect(user.log_data.meta).to eq("_r" => 2, "some_key" => "current_val")
    end

    it "returns nil if no information" do
      expect(user.at(time: time(350)).log_data.meta).to be_nil
    end

    it "returns meta for previous version" do
      expect(user.at(time: time(250)).log_data.meta).to eq("some_key" => "old_val")
    end
  end

  describe ".reload_log_data" do
    it "returns log_data" do
      expect(User).to receive(:where).and_call_original
      expect(user.reload_log_data).to eq(user.log_data)
    end
  end

  describe "#log_size" do
    subject { user.log_size }

    it { is_expected.to eq(user.log_data.size) }

    context "when model created within a without_logging block" do
      let(:user) { User.create!(name: "test") }

      before { Logidze.without_logging { user } }

      it { is_expected.to be_zero }
    end
  end

  describe ".reset_log_data" do
    let!(:user2) { user.dup.tap(&:save!) }
    let!(:user3) { user.dup.tap(&:save!) }

    before { User.limit(2).reset_log_data }

    it "nullify log_data column for a association" do
      expect(user.reload.log_size).to be_zero
      expect(user2.reload.log_size).to be_zero
    end

    it "not affect other model records" do
      expect(user3.reload.log_size).to eq 5
    end
  end

  describe "#reset_log_data" do
    subject { user.log_size }

    before { user.reset_log_data }

    it "nullify log_data column for a single record" do
      is_expected.to be_zero
    end
  end

  context "with ignore_log_data: true" do
    describe ".with_log_data" do
      it "generates the same query as model with ignore_log_data: false" do
        expect(NotLoggedPost.with_log_data.to_sql).to eq(
          Post.all.to_sql
        )
      end
    end
  end

  context "when logs contain outdated schema" do
    let(:user) do
      User.create!(
        name: "test",
        log_data: {
          "v" => 3,
          "h" =>
            [
              {"v" => 1, "ts" => time(100), "c" => {"age" => nil}},
              {"v" => 2, "ts" => time(120), "c" => {"age" => 1, "last_name" => "Harry"}},
              {"v" => 3, "ts" => time(200), "c" => {"name" => "Harry", "age" => 10}}
            ]
        }
      )
    end

    describe "#at" do
      it "returns version at specified time", :aggregate_failures do
        user_old = user.at(time: time(150))
        expect(user_old.name).to eq "test"
        expect(user_old.age).to eq 1
      end
    end

    describe "#diff_from" do
      it "returns diff from specified time" do
        expect(user.diff_from(version: 1))
          .to eq(
            "id" => user.id,
            "changes" =>
              {
                "age" => {"old" => nil, "new" => 10},
                "name" => {"old" => nil, "new" => "Harry"}
              }
          )
      end
    end
  end
end
