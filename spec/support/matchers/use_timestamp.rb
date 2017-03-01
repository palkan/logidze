# frozen_string_literal: true
RSpec::Matchers.define :use_timestamp do |expected|
  match do |record|
    record.log_data.current_version.time / 1000 == record.public_send(expected).to_i
  end
end

RSpec::Matchers.define :use_statement_timestamp do
  match do |record|
    # WARN: dividing by 100 for consistency. Always use Timecop to ensure valid tests.
    record.log_data.current_version.time / 100_000 == Time.current.to_i / 100
  end
end
