# frozen_string_literal: true

require "spec_helper"

describe "Logidze::History::Serializer", :sequel do
  subject { Logidze::History::Serializer }

  before { SequelModel::User.db.extension :pg_json }

  describe "#deserialize" do
    it "handles valid JSON" do
      val = subject.deserialize('{"a":"b"}')
      expect(val).to be_a(Logidze::History)
      expect(val.data).to eq "a" => "b"
    end

    it "handles valid JSON augmented with Sequel JSON support" do
      val = subject.deserialize(Sequel::Postgres::JSONBHash.new("a" => "b"))
      expect(val).to be_a(Logidze::History)
      expect(val.data).to eq "a" => "b"
    end

    it "handles valid Logidze History" do
      val = subject.deserialize(Logidze::History.new("a" => "b"))
      expect(val).to be_a(Logidze::History)
      expect(val.data).to eq "a" => "b"
    end

    it "handles nil" do
      expect(subject.deserialize(nil)).to be_nil
    end
  end

  describe "#serialize" do
    it "handles Logidze History" do
      expect(subject.serialize(Logidze::History.new("a" => "b")))
        .to eq '{"a":"b"}'
    end

    it "handles hash" do
      expect(subject.serialize("a" => "b"))
        .to eq '{"a":"b"}'
    end

    it "handles nil" do
      expect(subject.serialize(nil)).to be_nil
    end
  end
end
