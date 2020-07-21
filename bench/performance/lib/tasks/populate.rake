# frozen_string_literal: true

desc "Create test data"
task populate: :environment do
  Benchmarker.populate(ENV.fetch("N", 1_000).to_i)

  puts "Total users: #{User.count}"
  puts "Total logidze users: #{LogidzeUser.count}"
end

namespace :populate do
  task clean: :environment do
    Benchmarker.cleanup
  end

  task reset: ["populate:clean", "populate"]
end
