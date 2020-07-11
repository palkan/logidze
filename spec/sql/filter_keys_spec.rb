# frozen_string_literal: true

require "spec_helper"

describe "logidze_filter_keys" do
  before(:all) do
    declare_function "logidze_filter_keys"
  end

  after(:all) do
    drop_function "logidze_filter_keys(jsonb, text[], boolean)"
  end

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
