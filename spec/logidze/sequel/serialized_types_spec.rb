# frozen_string_literal: true

require "spec_helper"

describe Logidze::Model, :sequel do
  let(:user) do
    SequelModel::User.create(
      name: "test",
      extra: {gender: "X", social: {fb: [1, 2], vk: false}}.to_json,
      settings: "{sms,mail}",
      log_data: {
        "v" => 5,
        "h" =>
          [
            {"v" => 1, "ts" => time(100), "c" => {"name" => nil, "age" => nil, "active" => nil, "extra" => nil, "settings" => nil}},
            {"v" => 2, "ts" => time(200), "c" => {"extra" => {"gender" => "M", "social" => {"fb" => [1]}}.to_json}},
            {"v" => 3, "ts" => time(200), "r" => 1, "c" => {"settings" => "{mail}"}},
            {"v" => 4, "ts" => time(300), "c" => {"extra" => {"gender" => "F", "social" => {"fb" => [2]}}.to_json}},
            {"v" => 5, "ts" => time(400), "r" => 2, "c" => {"extra" => {"gender" => "X", "social" => {"fb" => [1, 2], "vk" => false}}.to_json, "settings" => "{sms,mail}"}}
          ]
      }.to_json
    )
  end

  describe "#at" do
    it "returns version at specified time", :aggregate_failures do
      user_old = user.at(time: time(350))
      expect(user_old.extra["gender"]).to eq "F"
      expect(user_old.extra["social"]).to eq("fb" => [2])
      expect(user_old.settings).to eq(["mail"])

      user_old = user.at(time: time(250))
      expect(user_old.extra["gender"]).to eq "M"
      expect(user_old.extra["social"]).to eq("fb" => [1])
      expect(user_old.settings).to eq(["mail"])
    end
  end

  describe "#diff_from" do
    it "returns diff from specified time" do
      expect(user.diff_from(version: 3))
        .to eq(
          "id" => user.id,
          "changes" =>
            {
              "extra" => {"old" => {"gender" => "M", "social" => {"fb" => [1]}}, "new" => {"gender" => "X", "social" => {"fb" => [1, 2], "vk" => false}}},
              "settings" => {"old" => ["mail"], "new" => %w[sms mail]}
            }
        )
    end
  end
end
