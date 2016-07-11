# frozen_string_literal: true
require "acceptance_helper"

describe "Logidze migrations" do
  describe "#install" do
    include_context "cleanup migrations"

    it "creates migration" do
      successfully "rails generate logidze:install"

      successfully "rake db:migrate"

      successfully "rake db:rollback"

      successfully "rake db:rollback"
    end

    it "creates update migration" do
      successfully "rails generate logidze:install --update"

      successfully "rake db:migrate"

      successfully "rake db:rollback"
    end
  end

  describe "#model" do
    include_context "cleanup migrations"
    include_context "cleanup models"

    before do
      successfully "rails generate logidze:install"
      successfully "rake db:migrate"

      successfully "rails generate model Movie"
      successfully "rake db:migrate"
    end

    it "creates migration and patches model" do
      successfully "rails generate logidze:model Movie"

      verify_file_contains "app/models/movie.rb", "has_logidze"

      successfully "rake db:migrate"

      successfully "rake db:rollback"
    end
  end
end
