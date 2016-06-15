require 'benchmark/ips'
require './setup'

# How many records do you want?
N = (ENV['N'] || '100').to_i

# How many version each record has?
V = (ENV['V'] || '10').to_i

# Benchmark run time
BM_TIME = (ENV['BM_TIME'] || 5).to_i

BM_WARMUP = [(BM_TIME / 10), 2].max

LogidzeBench.cleanup
LogidzeBench.populate(N)

ts1 = LogidzeBench.generate_versions(V/2)

LogidzeBench.generate_versions(V/2)

Benchmark.ips do |x|
  x.config(time: BM_TIME, warmup: BM_WARMUP)

  x.report('PT DIFF') do
    User.random(N/2).diff_from(ts1)
  end

  x.report('PT (join) DIFF') do
    User.random(N/2).diff_from_joined(ts1)
  end

  x.report('Logidze DIFF') do
    LogidzeUser.random(N/2).diff_from(ts1)
  end
end
