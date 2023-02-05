# frozen_string_literal: true

require "acceptance_helper"

describe "logidze_fetch_primary_keys" do
  let(:partitioned_table_name) { PartitionedPost.table_name }
  let(:table_name) { Post.table_name }

  specify do
    res = sql "select logidze_fetch_primary_keys('#{table_name}')"

    expect(res).to eq('{id}')
  end

  specify "composite primary keys" do
    res = sql "select logidze_fetch_primary_keys('#{partitioned_table_name}')"

    expect(res).to eq('{id logdate}')
  end
end
