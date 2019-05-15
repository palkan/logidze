# frozen_string_literal: true

require "benchmark/ips"
require "./setup"

params = {
  email: Faker::Internet.email,
  position: Faker::Number.number(3),
  name: Faker::Name.name,
  age: Faker::Number.number(2),
  bio: Faker::Lorem.paragraph
}

Benchmark.ips do |x|
  x.report("PaperTrail INSERT") do
    User.create!(params)
  end

  x.report("Logidze INSERT") do
    LogidzeUser.create!(params)
  end
end
