# frozen_string_literal: true

require_relative "../config/environment"

require "memory_profiler"

# How many records do you want?
N = (ENV["N"] || "10").to_i

# How many version each record has?
V = (ENV["V"] || "10").to_i

Benchmarker.cleanup
Benchmarker.populate(N)
Benchmarker.generate_versions(V)

module MemoryReport
  KILO_BYTE = 1024
  MEGA_BYTE = 1024 * 1024

  module_function

  def call(msg, relation)
    buffer = nil
    delta = N / 10
    r0 = MemoryProfiler.report do
      buffer = relation.random(N - delta).to_a
    end

    buffer = nil
    r1 = MemoryProfiler.report do
      buffer = relation.to_a
    end

    $stdout.puts msg
    $stdout.puts "Total Allocated:\t\t\t\t#{to_human_size(r1.total_allocated_memsize)}"
    $stdout.puts "Total Retained:\t\t\t\t\t#{to_human_size(r1.total_retained_memsize)}"
    $stdout.puts "Retained_memsize memory (per record):\t\t#{to_human_size((r1.total_retained_memsize - r0.total_retained_memsize) / delta)}\n"
  end

  module_function

  def to_human_size(size)
    if size > MEGA_BYTE
      "#{(size.to_f / MEGA_BYTE).round(2)} MB"
    elsif size > KILO_BYTE
      "#{(size.to_f / KILO_BYTE).round(2)} KB"
    else
      "#{size} B"
    end
  end
end

MemoryReport.call("Plain records", User.all)
MemoryReport.call("PT with versions", PaperTrailUser.joins(:versions).all)
MemoryReport.call("Logidze records", LogidzeUser.all)
