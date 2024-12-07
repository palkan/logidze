# frozen_string_literal: true

require "acceptance_helper"

describe "logidze_snapshot" do
  let(:now) { Time.zone.local(1989, 7, 10, 18, 23, 33) }
  let(:now_to_s) do
    now.respond_to?(:to_fs) ? now.to_fs(:db) : now.to_s(:db)
  end

  let(:data) { %('{"title": "Feel me", "rating": 42, "name": "Jack", "extra": {"gender": "X"}, "updated_at": "#{now_to_s}"}'::jsonb) }

  specify "without optional args" do
    res = sql "select logidze_snapshot(#{data})"

    snapshot = JSON.parse(res)

    expect(snapshot["v"]).to eq 1
    expect(snapshot["h"].size).to eq 1

    version = snapshot["h"].first

    expect(version).to match({
      "ts" => an_instance_of(Integer),
      "v" => 1,
      "c" => a_hash_including({"title" => "Feel me", "rating" => 42, "name" => "Jack", "extra" => '{"gender": "X"}'})
    })

    expect(Time.at(version["ts"] / 1000) - now).to be > 1.year
  end

  specify "with timestamp column" do
    res = sql "select logidze_snapshot(#{data}, 'updated_at')"

    snapshot = JSON.parse(res)

    expect(snapshot["v"]).to eq 1
    expect(snapshot["h"].size).to eq 1

    version = snapshot["h"].first

    expect(version).to match({
      "ts" => now.to_i * 1_000,
      "v" => 1,
      "c" => a_hash_including({"title" => "Feel me", "rating" => 42, "name" => "Jack"})
    })
  end

  specify "with columns filtering" do
    res = sql "select logidze_snapshot(#{data}, 'null', '{name}', true)"

    snapshot = JSON.parse(res)

    expect(snapshot["v"]).to eq 1
    expect(snapshot["h"].size).to eq 1

    version = snapshot["h"].first

    expect(version).to match({
      "ts" => an_instance_of(Integer),
      "v" => 1,
      "c" => {"name" => "Jack"}
    })

    expect(Time.at(version["ts"] / 1000) - now).to be > 1.year
  end

  specify "with columns filtering and timestamp column" do
    res = sql "select logidze_snapshot(#{data}, 'updated_at', '{name}', true)"

    snapshot = JSON.parse(res)

    expect(snapshot["v"]).to eq 1
    expect(snapshot["h"].size).to eq 1

    version = snapshot["h"].first

    expect(version).to eq({
      "ts" => now.to_i * 1_000,
      "v" => 1,
      "c" => {"name" => "Jack"}
    })
  end
end
