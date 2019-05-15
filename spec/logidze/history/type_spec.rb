# frozen_string_literal: true

require "spec_helper"

describe "Logidze::History::Type", :rails5 do
  subject { Logidze::History::Type.new }

  describe "#cast" do
    it "handles hash" do
      val = subject.cast("a" => "b")
      expect(val).to be_a(Logidze::History)
      expect(val.data).to eq "a" => "b"
    end

    it "handles nil" do
      expect(subject.cast(nil)).to be_nil
    end
  end

  describe "#deserialize" do
    it "handles valid json" do
      val = subject.deserialize('{"a":"b"}')
      expect(val).to be_a(Logidze::History)
      expect(val.data).to eq "a" => "b"
    end

    it "handles nil" do
      expect(subject.deserialize(nil)).to be_nil
    end
  end

  describe "#serialize" do
    it "handles nil" do
      expect(subject.serialize(nil)).to be_nil
    end

    it "handles history" do
      expect(subject.serialize(Logidze::History.new("a" => "b")))
        .to eq '{"a":"b"}'
    end
  end

  describe "#changed_in_place?" do
    let(:raw_data) { '{"v":1}' }

    it "detects changes", :aggregate_failures do
      val = subject.deserialize(raw_data)
      expect(subject.changed_in_place?(raw_data, val)).to eq false

      val.version = 2
      expect(subject.changed_in_place?(raw_data, val)).to eq true
    end
  end
end
