# frozen_string_literal: true

require "benchmark/ips"
require_relative "../config/environment"

params = Benchmarker.fake_params

# Benchmark run time
BM_TIME = (ENV["BM_TIME"] || 5).to_i
BM_WARMUP = [(BM_TIME / 10), 2].max

Benchmark.ips do |x|
  x.config(time: BM_TIME, warmup: BM_WARMUP)

  x.report("Plain INSERT") do
    User.create!(params)
  end

  x.report("PaperTrail INSERT") do
    PaperTrailUser.create!(params)
  end

  x.report("Logidze INSERT") do
    LogidzeUser.create!(params)
  end

  x.compare!
end
