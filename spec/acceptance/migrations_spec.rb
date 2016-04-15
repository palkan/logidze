require "acceptance_helper"

describe "Logidze migrations" do
  include_context "cleanup migrations"

  describe "#install" do
    it "creates migration" do
      successfully "rails generate logidze:install"

      successfully "rake db:migrate"

      successfully "rake db:rollback"
    end
  end

  describe "#model" do
    include_context "cleanup models"

    it "creates migration and patches model" do
      successfully "rails generate model Post"

      successfully "rake db:migrate"

      successfully "rails generate logidze:model Post"

      verify_file_contains "app/models/post.rb", "has_logidze"

      successfully "rake db:migrate"

      successfully "rake db:rollback"
    end
  end
end
