# frozen_string_literal: true
shared_context "setup models with timestamp column" do |timestamp_column|
  include_context "cleanup migrations"

  before(:all) do
    param = "--timestamp_column #{timestamp_column}" if timestamp_column
    Dir.chdir("#{File.dirname(__FILE__)}/../../dummy") do
      # Post has an 'updated_at' column
      successfully "rails generate logidze:model post #{param}"
      # User has a 'time' column
      successfully "rails generate logidze:model user --only-trigger #{param}"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end
end
