# frozen_string_literal: true

require "benchmark/ips"
require_relative "../config/environment"

# How many records do you want?
N = (ENV["N"] || "100").to_i

# How many version each record has?
V = (ENV["V"] || "10").to_i

# Benchmark run time
BM_TIME = (ENV["BM_TIME"] || 5).to_i

BM_WARMUP = [(BM_TIME / 10), 2].max

Benchmarker.cleanup
Benchmarker.populate(N, skip_user: true)

ts1 = Benchmarker.generate_versions(V / 2)

Benchmarker.generate_versions(V / 2)

Benchmark.ips do |x|
  x.config(time: BM_TIME, warmup: BM_WARMUP)

  x.report("PT DIFF") do
    PaperTrailUser.random(N / 2).diff_from(ts1)
  end

  x.report("PT (join) DIFF") do
    PaperTrailUser.random(N / 2).diff_from_joined(ts1)
  end

  x.report("Logidze DIFF") do
    LogidzeUser.random(N / 2).diff_from(time: ts1)
  end

  x.compare!
end
