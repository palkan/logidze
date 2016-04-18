# frozen_string_literal: true
require 'benchmark'

letters = ("a".."z").to_a

letters_hash = Hash[letters.zip((1..(letters.size)).to_a)]

module X
  def self.each_with_object(obj)
    obj.each_with_object({}) do |p, acc|
      acc[p.first] = p.last if p.first < "l"
    end
  end

  def self.each_object(obj)
    h = {}
    obj.each do |k, v|
      h[k] = v if k < "l"
    end
  end
end

n = 1_000_000

Benchmark.bm do |x|
  x.report("#each_with_object") { n.times { ; X.each_with_object(letters_hash) } }
  x.report("#each 					 ") { n.times { ; X.each_object(letters_hash) } }
end
