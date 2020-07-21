# frozen_string_literal: true

require "benchmark/ips"
require_relative "../config/environment"

# How many records do you want?
N = (ENV["N"] || "100").to_i

# How many records to load in the benchmark?
M = (N / 10)

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

  x.report("PT AT single") do
    PaperTrailUser.random.paper_trail.version_at(ts1)
  end

  x.report("Logidze AT single") do
    LogidzeUser.random.at(time: ts1)
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(time: BM_TIME, warmup: BM_WARMUP)

  x.report("PT AT many") do
    PaperTrailUser.random(M).map { |u| u.paper_trail.version_at(ts1) }
  end

  x.report("Logidze AT many") do
    LogidzeUser.random(M).at(time: ts1)
  end

  x.compare!
end
