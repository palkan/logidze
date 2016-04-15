require 'spec_helper'

describe Logidze::Model, :db do
  let(:user) do
    User.create!(
      name: 'test',
      age: 10,
      active: false,
      log_data: {
        'v' => 4,
        'h' =>
          [
            { 'v' => 1, 'ts' => time(100), 'c' => { 'name' => nil, 'age' => nil, 'active' => nil } },
            { 'v' => 2, 'ts' => time(200), 'c' => { 'name' => 'test', 'active' => true } },
            { 'v' => 3, 'ts' => time(300), 'c' => { 'age' => 0 } },
            { 'v' => 4, 'ts' => time(400), 'c' => { 'age' => 10, 'active' => false } }
          ]
      })
  end

  describe "#at" do
    it "returns version at first time", :aggregate_failures do
      user_old = user.at(time(100))
      expect(user_old.name).to be_nil
      expect(user_old.age).to be_nil
      expect(user_old.active).to be_nil
    end

    it "returns version at intermediate time (one change)", :aggregate_failures do
      user_old = user.at(time(140))
      expect(user_old.name).to be_nil
      expect(user_old.age).to be_nil
      expect(user_old.active).to be_nil
    end

    it "returns version at intermediate time (several changes)", :aggregate_failures do
      user_old = user.at(time(350))
      expect(user_old.name).to eq 'test'
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "returns nil if time is invalid (too early)" do
      expect(user.at(time(99))).to be_nil
    end

    it "returns self if actual version" do
      expect(user.at(time(401))).to be_equal(user)
    end

    it "returns dup", :aggregate_failures do
      user_old = user.at(time(100))
      expect(user_old).not_to be_equal(user)

      user_old.age = 100
      expect(user.age).to eq 10
    end

    it "handles time as string", :aggregate_failures do
      user_old = user.at("2016-04-12 12:05:50")
      expect(user_old.name).to eq 'test'
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "handles time as Time", :aggregate_failures do
      user_old = user.at(Time.new(2016, 04, 12, 12, 05, 50))
      expect(user_old.name).to eq 'test'
      expect(user_old.age).to eq 0
      expect(user_old.active).to eq true
    end

    it "handles time as Date", :aggregate_failures do
      user_old = user.at(Date.new(2016, 04, 13))
      expect(user_old).to be_equal user
    end
  end

  describe "#at!" do
    it "update object in-place", :aggregate_failures do
      user.at!(time(350))

      expect(user.name).to eq 'test'
      expect(user.age).to eq 0
      expect(user.active).to eq true

      expect(user.changes).to eq("age" => [10, 0], "active" => [false, true])
    end
  end

  describe "#diff_from" do
    it "returns diff from initial" do
      expect(user.diff_from(time))
        .to eq(
          "id" => user.id,
          "changes" =>
            {
              "name" => { "old" => nil, "new" => "test" },
              "age" => { "old" => nil, "new" => 10 },
              "active" => { "old" => nil, "new" => false }
            }
        )
    end

    it "returns diff from intermediate time" do
      expect(user.diff_from(time(350)))
        .to eq(
          "id" => user.id,
          "changes" =>
            {
              "age" => { "old" => 0, "new" => 10 },
              "active" => { "old" => true, "new" => false }
            }
        )
    end
  end

  describe "undo!" do
    it "revert record to previous state", :aggregate_failures do
      expect(user.undo!).to eq true
      user.reload
      expect(user.name).to eq 'test'
      expect(user.age).to eq 0
      expect(user.active).to eq true
    end

    it "revert record several times", :aggregate_failures do
      user.undo!
      user.undo!
      user.undo!
      user.reload
      expect(user.name).to be_nil
      expect(user.age).to be_nil
      expect(user.active).to be_nil
    end

    it "return false no possible undo" do
      u = User.create!(
        log_data: {
          'v' => 1,
          'h' =>
          [
            { 'v' => 1, 'ts' => time(100), 'c' => { 'name' => nil, 'age' => nil, 'active' => nil } }
          ]
        })

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
      expect(user.name).to eq 'test'
      expect(user.age).to eq 10
      expect(user.active).to eq false
    end

    it "revert record several times", :aggregate_failures do
      user.undo!
      user.reload

      expect(user.name).to eq 'test'
      expect(user.age).to be_nil
      expect(user.active).to eq true

      user.redo!
      user.redo!
      user.reload

      expect(user.name).to eq 'test'
      expect(user.age).to eq 10
      expect(user.active).to eq false
    end

    it "return false no possible redo" do
      u = User.create!(
        log_data: {
          'v' => 1,
          'h' =>
          [
            { 'v' => 1, 'ts' => time(100), 'c' => { 'name' => nil, 'age' => nil, 'active' => nil } }
          ]
        })

      expect(u.redo!).to eq false
    end
  end

  describe ".at" do
    before { user }

    it "returns reverted records", :aggregate_failures do
      u = User.at(time(350)).first

      expect(u.name).to eq 'test'
      expect(u.age).to eq 0
      expect(u.active).to eq true
    end

    it "returns reverted records when called on relation", :aggregate_failures do
      u = User.where(active: false).order(age: :desc).at(time(350)).first

      expect(u.name).to eq 'test'
      expect(u.age).to eq 0
      expect(u.active).to eq true
    end

    it "skips nil records" do
      User.create!(
        log_data: {
          'v' => 1,
          'h' =>
            [
              { 'v' => 1, 'ts' => time(400), 'c' => { 'name' => nil, 'age' => nil, 'active' => nil } }
            ]
        }
      )

      expect(User.at(time(350)).size).to eq 1
    end
  end

  describe ".diff_from" do
    before { user }

    it "returns diffs for records", :aggregate_failures do
      expect(
        User.diff_from(time(350)).first
      ).to eq(
        "id" => user.id,
        "changes" =>
          {
            "age" => { "old" => 0, "new" => 10 },
            "active" => { "old" => true, "new" => false }
          }
      )
    end

    it "returns diffs for records when called on relation", :aggregate_failures do
      expect(
        User.where(active: false).order(age: :desc).diff_from(time(350)).first
      ).to eq(
        "id" => user.id,
        "changes" =>
          {
            "age" => { "old" => 0, "new" => 10 },
            "active" => { "old" => true, "new" => false }
          }
      )
    end
  end
end
