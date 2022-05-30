# frozen_string_literal: true

require "benchmark/ips"
require_relative "../config/environment"

# Benchmark run time
BM_TIME = (ENV["BM_TIME"] || 5).to_i
BM_WARMUP = [(BM_TIME / 10), 2].max

params = Benchmarker.fake_params.slice(:age, :email)

params2 = Benchmarker.fake_params

Benchmarker.cleanup
Benchmarker.populate(ENV.fetch("N", 1_000).to_i)

class LogidzeUser
  # Loading log_data could produce a bit of overhead but it's out of scope for this benchmark
  self.ignored_columns += ["log_data"]
end

JSON_COLUMNS = %i[data dump].freeze

Benchmark.ips do |x|
  x.config(time: BM_TIME, warmup: BM_WARMUP)

  x.report("Plain UPDATE #1") do
    User.random.update!(params)
  end

  x.report("PT UPDATE #1") do
    PaperTrailUser.random.update!(params)
  end

  x.report("Logidze UPDATE #1") do
    LogidzeUser.random.update!(params)
  end

  x.compare!
end

Benchmark.ips do |x|
  x.config(time: BM_TIME, warmup: BM_WARMUP)

  x.report("Plain UPDATE #2") do
    user = User.random
    user.update!(params2.except(*JSON_COLUMNS))
    user.update!(params2.slice(*JSON_COLUMNS))
  end

  x.report("PT UPDATE #2") do
    user = PaperTrailUser.random
    user.update!(params2.except(*JSON_COLUMNS))
    user.update!(params2.slice(*JSON_COLUMNS))
  end

  x.report("Logidze UPDATE #2") do
    user = LogidzeUser.random
    user.update!(params2.except(*JSON_COLUMNS))
    user.update!(params2.slice(*JSON_COLUMNS))
  end

  x.compare!
end
