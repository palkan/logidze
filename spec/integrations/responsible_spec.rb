# frozen_string_literal: true
require "acceptance_helper"

describe "Logidze responsibility", :db do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:install"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  describe ".with_responsible" do
  end
end
