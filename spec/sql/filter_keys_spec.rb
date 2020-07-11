# frozen_string_literal: true

require "acceptance_helper"

describe "logidze_filter_keys" do
  let(:data) { %q('{"title": "Feel me", "rating": 42, "name": "Jack"}'::jsonb) }

  specify "only filter" do
    res = sql "select logidze_filter_keys(#{data}, '{title,rating}', true)"

    expect(JSON.parse(res)).to eq({"title" => "Feel me", "rating" => 42})
  end

  specify "except filter" do
    res = sql "select logidze_filter_keys(#{data}, '{rating}')"

    expect(JSON.parse(res)).to eq({"title" => "Feel me", "name" => "Jack"})
  end
end
