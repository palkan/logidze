# frozen_string_literal: true
require "spec_helper"

describe Logidze::History do
  let(:data) do
    {
      'v' => 5,
      'h' =>
        [
          { 'v' => 1, 'ts' => time(100), 'c' => { 'name' => nil, 'age' => nil, 'active' => nil } },
          { 'v' => 2, 'ts' => time(200), 'c' => { 'active' => true } },
          { 'v' => 3, 'ts' => time(200), 'c' => { 'name' => 'test' } },
          { 'v' => 4, 'ts' => time(300), 'c' => { 'age' => 0 } },
          { 'v' => 5, 'ts' => time(400), 'c' => { 'age' => 10, 'active' => false } }
        ]
    }
  end

  let(:json_data) { ActiveSupport::JSON.encode(data) }

  subject { described_class.new data }

  describe '.load' do
    subject { described_class }

    it "loads json" do
      expect(subject.load(json_data)).to be_a described_class
    end

    it "handles nil" do
      expect(subject.load(nil)).to be_nil
    end
  end

  describe ".dump" do
    subject { described_class }

    it "returns json" do
      expect(subject.dump(described_class.new(data))).to eq json_data
    end
  end

  describe "#version" do
    specify { expect(subject.version).to eq 5  }
  end

  describe "#versions" do
    specify { expect(subject.versions.size).to eq 5 }
    specify { expect(subject.versions.first).to be_a(Logidze::History::Version) }
  end

  describe "#changes_to" do
    it "returns version at first time" do
      data = subject.changes_to(time: time(100))
      expect(data).to eq("name" => nil, "age" => nil, "active" => nil)
    end

    it "returns version at intermediate time (one change)" do
      data = subject.changes_to(time: time(140))
      expect(data).to eq("name" => nil, "age" => nil, "active" => nil)
    end

    it "returns version at intermediate time (several changes)" do
      data = subject.changes_to(time: time(350))
      expect(data).to eq("name" => "test", "age" => 0, "active" => true)
    end

    it "returns empty hash if time is invalid (too early)" do
      expect(subject.changes_to(time: time(99))).to be_empty
    end

    it "returns specified version state" do
      data = subject.changes_to(version: 4)
      expect(data).to eq("name" => "test", "age" => 0, "active" => true)
    end

    it "returns change with base diff and from" do
      data = subject.changes_to(version: 4, data: { "name" => "abc", "active" => true }, from: 3)
      expect(data).to eq("name" => "test", "age" => 0, "active" => true)
    end

    it "raises if no time nor version" do
      expect { subject.changes_to }.to raise_error /Time or version must be specified/
    end
  end

  describe "#diff_from" do
    it "returns diff from initial" do
      expect(subject.diff_from(time: time))
        .to eq(
          "name" => { "old" => nil, "new" => "test" },
          "age" => { "old" => nil, "new" => 10 },
          "active" => { "old" => nil, "new" => false }
        )
    end

    it "returns diff from intermediate time" do
      expect(subject.diff_from(time: time(350)))
        .to eq(
          "age" => { "old" => 0, "new" => 10 },
          "active" => { "old" => true, "new" => false }
        )
    end

    it "returns diff from version" do
      expect(subject.diff_from(version: 4))
        .to eq(
          "age" => { "old" => 0, "new" => 10 },
          "active" => { "old" => true, "new" => false }
        )
    end

    it "raises if no time nor version" do
      expect { subject.diff_from }.to raise_error /Time or version must be specified/
    end
  end
end
