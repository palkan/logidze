# frozen_string_literal: true
shared_context "cleanup migrations" do
  before(:all) { @old_migrations = Dir["spec/dummy/db/migrate/*"] }
  after(:all) do
    all_versions = ActiveRecord::Migrator.get_all_versions
    (Dir["spec/dummy/db/migrate/*"] - @old_migrations).each do |path|
      version = path.match(%r{\/(\d+)\_[^\.]+\.rb$})[1]
      if all_versions.include?(version.to_i)
        Dir.chdir("#{File.dirname(__FILE__)}/../../dummy") do
          suppress_output do
            system <<-CMD
              VERSION=#{version} rake db:migrate:down
            CMD
          end
        end
      end
      FileUtils.rm(path)
    end
  end
end

shared_context "cleanup models" do
  before(:all) { @old_models = Dir["spec/dummy/app/models/*"] }
  after(:all) { FileUtils.rm(Dir["spec/dummy/app/models/*"] - @old_models) }
end
