# frozen_string_literal: true

require "acceptance_helper"

describe "track_deletes", :db, skip: !LOGIDZE_DETACHED do
  include_context "cleanup migrations"

  before(:all) do
    Dir.chdir("#{File.dirname(__FILE__)}/../dummy") do
      successfully "rails generate logidze:model trashable --track-deletes"
      successfully "rake db:migrate"

      # Close active connections to handle db variables
      ActiveRecord::Base.connection_pool.disconnect!
    end

    Trashable.reset_column_information
  end

  let!(:trashable) { Trashable.create!(name: "Delete Me", rating: 10) }

  describe "#destroy!" do
    it "keeps the logidze_data row and appends a deletion version" do
      trashable.update!(rating: 20)
      expect(trashable.reload.log_version).to eq 2

      trashable.destroy!

      data = Logidze::LogidzeData.find_by!(
        loggable_type: "Trashable",
        loggable_id: trashable.id
      )

      expect(data.log_data).to be_a(Logidze::History)
      expect(data.log_data.version).to eq 3

      last = data.log_data.versions.last
      expect(last.data["_d"]).to be true
      expect(last.changes).to eq({})
    end

    it "captures responsible and meta on the deletion version" do
      Logidze.with_responsible(42) do
        Logidze.with_meta({"reason" => "gdpr"}) do
          trashable.destroy!
        end
      end

      data = Logidze::LogidzeData.find_by!(
        loggable_type: "Trashable",
        loggable_id: trashable.id
      )

      last = data.log_data.versions.last
      expect(last.data["_d"]).to be true
      expect(last.responsible_id).to eq 42
      expect(last.meta).to include("reason" => "gdpr")
    end

    it "does not create a deletion version when logging is disabled" do
      expect {
        Logidze.without_logging { trashable.destroy! }
      }.not_to change {
        Logidze::LogidzeData.where(
          loggable_type: "Trashable",
          loggable_id: trashable.id
        ).first&.log_data&.version
      }
    end
  end

  describe "with no prior log_data" do
    it "seeds a snapshot from OLD and appends a deletion version" do
      # Wipe log_data so the delete trigger has no prior state.
      trashable.reset_log_data
      expect(trashable.reload.log_data).to be_nil

      trashable.destroy!

      data = Logidze::LogidzeData.find_by!(
        loggable_type: "Trashable",
        loggable_id: trashable.id
      )
      expect(data.log_data.version).to eq 2
      expect(data.log_data.versions.first.changes).to include("name" => "Delete Me")
      expect(data.log_data.versions.last.data["_d"]).to be true
    end
  end

  describe "has_logidze without track_deletes" do
    it "raises when combined with inline log placement" do
      expect {
        Class.new(ActiveRecord::Base) do
          self.table_name = "posts"
          has_logidze detached: false, track_deletes: true
        end
      }.to raise_error(ArgumentError, /detached log placement/)
    end
  end
end
