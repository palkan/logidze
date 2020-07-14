# frozen_string_literal: true

shared_context "cleanup migrations" do
  prepend_before(:all) do
    @old_migrations = Dir["spec/dummy/db/migrate/*"]
    @old_functions = Dir["spec/dummy/db/functions/*"]
    @old_triggers = Dir["spec/dummy/db/triggers/*"]
  end

  append_after(:all) do
    (Dir["spec/dummy/db/migrate/*"] - @old_migrations).each do |path|
      version = path.match(%r{\/(\d+)\_[^\.]+\.rb$})[1]
      Dir.chdir("#{File.dirname(__FILE__)}/../../dummy") do
        suppress_output do
          system <<-CMD
              VERSION=#{version} rake db:migrate:down
          CMD
        end
      end
      FileUtils.rm(path)
    end

    (
      (Dir["spec/dummy/db/functions/*"] - @old_functions) +
      (Dir["spec/dummy/db/triggers/*"] - @old_triggers)
    ).each { |path| File.delete(path) }
  end
end

shared_context "cleanup models" do
  before(:all) { @old_models = Dir["spec/dummy/app/models/*"] }
  after(:all) { FileUtils.rm(Dir["spec/dummy/app/models/*"] - @old_models) }
end
