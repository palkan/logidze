require 'benchmark/ips'
require './setup'

params = {
  age: Faker::Number.number(2),
  email: Faker::Internet.email
}

params2 = {
  email: Faker::Internet.email,
  position: Faker::Number.number(3),
  name: Faker::Name.name,
  age: Faker::Number.number(2),
  bio: Faker::Lorem.paragraph
}

LogidzeBench.cleanup
LogidzeBench.populate

Benchmark.ips do |x|
  x.report('PT UPDATE #1') do
    User.random.update!(params)
  end

  x.report('Logidze UPDATE #1') do
    LogidzeUser.random.update!(params)
  end

  x.report('PT UPDATE #2') do
    User.random.update!(params2)
  end

  x.report('Logidze UPDATE #2') do
    LogidzeUser.random.update!(params2)
  end
end
