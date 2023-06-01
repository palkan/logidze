# frozen_string_literal: true

require "spec_helper"
require "logidze/utils/function_definitions"

describe Logidze::Utils::FunctionDefinitions do
  describe ".from_fs" do
    subject { described_class.from_fs }

    it "returns all library functions" do
      is_expected.to include(func_def("logidze_logger", 3, ""))
      is_expected.to include(func_def("logidze_logger_after", 3, ""))
      is_expected.to include(func_def("logidze_snapshot", 3, "jsonb, text, text[], boolean"))
      is_expected.to include(func_def("logidze_filter_keys", 1, "jsonb, text[], boolean"))
      is_expected.to include(func_def("logidze_compact_history", 1, "jsonb, integer"))
      is_expected.to include(func_def("logidze_capture_exception", 1, "jsonb"))
      is_expected.to include(func_def("logidze_version", 2, "bigint, jsonb, timestamp with time zone"))
    end
  end

  describe ".from_db" do
    subject { described_class.from_db }

    it "returns all functions from db without signatures" do
      is_expected.to include(func_def("logidze_logger", 3))
      is_expected.to include(func_def("logidze_logger_after", 3))
      is_expected.to include(func_def("logidze_snapshot", 3))
      is_expected.to include(func_def("logidze_filter_keys", 1))
      is_expected.to include(func_def("logidze_compact_history", 1))
      is_expected.to include(func_def("logidze_capture_exception", 1))
      is_expected.to include(func_def("logidze_version", 2))
    end
  end

  def func_def(*params)
    Logidze::Utils::FuncDef.new(*params)
  end
end
