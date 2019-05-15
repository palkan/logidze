# frozen_string_literal: true

require "spec_helper"

describe Logidze::History::Version do
  describe "#responsible_id" do
    it "takes value from meta" do
      subject = described_class.new("m" => {Logidze::History::Version::META_RESPONSIBLE => 2})
      expect(subject.responsible_id).to eq(2)
    end

    it "takes user root value when meta key is missing" do
      subject = described_class.new(Logidze::History::Version::RESPONSIBLE => 1)
      expect(subject.responsible_id).to eq(1)
    end

    it "prefers meta value over the root one" do
      subject = described_class.new(
        Logidze::History::Version::RESPONSIBLE => 1,
        "m" => {Logidze::History::Version::META_RESPONSIBLE => 2}
      )
      expect(subject.responsible_id).to eq(2)
    end
  end
end
