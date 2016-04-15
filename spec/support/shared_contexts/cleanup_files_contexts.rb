shared_context "cleanup migrations" do
  before(:all) { @old_migrations = Dir["spec/dummy/db/migrate/*"] }
  after(:all) { FileUtils.rm(Dir["spec/dummy/db/migrate/*"] - @old_migrations) }
end

shared_context "cleanup models" do
  before(:all) { @old_models = Dir["spec/dummy/app/models/*"] }
  after(:all) { FileUtils.rm(Dir["spec/dummy/app/models/*"] - @old_models) }
end
