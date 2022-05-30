# frozen_string_literal: true

module Benchmarker
  module_function

  def populate(n = 1_000, skip_user: false)
    ts = Time.current

    $stdout.print "Generating #{n} records... "

    n.times do
      params = fake_params
      User.create!(params) unless skip_user
      PaperTrailUser.create!(params)
      LogidzeUser.create!(params)
    end

    $stdout.puts "Done in #{Time.current - ts}s"
  end

  def cleanup
    LogidzeUser.delete_all
    PaperTrailUser.delete_all
    User.delete_all
    PaperTrail::Version.delete_all
  end

  def generate_versions(num = 1)
    ts = Time.current

    $stdout.print "Generating #{num} version for each record... "

    num.times do
      PaperTrailUser.find_each do |u|
        u.update!(fake_params(sample: true))
      end

      LogidzeUser.find_each do |u|
        u.update!(fake_params(sample: true))
      end

      # make at least 1 second between versions
      sleep 1
    end

    $stdout.puts "Done in #{Time.current - ts}s"

    Time.now
  end

  def fake_params(sample: false)
    params = {
      email: Faker::Internet.email,
      position: Faker::Number.number(digits: 3),
      name: Faker::Name.name,
      age: Faker::Number.number(digits: 2),
      bio: Faker::Lorem.paragraph,
      dump: JSON.parse(Faker::Json.shallow_json),
      data: JSON.parse(Faker::Json.shallow_json)
    }

    return params.slice(%i[email position name age bio].sample) if sample
    params
  end
end
