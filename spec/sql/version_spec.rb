# frozen_string_literal: true

require "acceptance_helper"

describe "logidze_version" do
  let(:data) { %q('{"title": "Feel me", "rating": 42, "name": "Jack"}'::jsonb) }

  specify do
    res = sql "select logidze_version(23, #{data}, statement_timestamp())"

    version = JSON.parse(res)

    expect(version).to match({
      "ts" => an_instance_of(Integer),
      "v" => 23,
      "c" => {"title" => "Feel me", "rating" => 42, "name" => "Jack"}
    })
  end

  specify "with meta" do
    res = Logidze.with_meta({cat: "matroskin"}) do
      sql "select logidze_version(43, #{data}, statement_timestamp())"
    end

    version = JSON.parse(res)

    expect(version).to match({
      "ts" => an_instance_of(Integer),
      "v" => 43,
      "c" => {"title" => "Feel me", "rating" => 42, "name" => "Jack"},
      "m" => {"cat" => "matroskin"}
    })
  end
end
