# frozen_string_literal: true

# This fix avoids adding duplicate trigger definitions from schema.rb due to multiple schemas.
# Put it somewhere under lib/tasks/*.rake to load during the `rails db:<smth>` execution.

require "fx/adapters/postgres/triggers"

Fx::Adapters::Postgres::Triggers.singleton_class.prepend(Module.new do
  def all(*args)
    super.uniq(&:name)
  end
end)
