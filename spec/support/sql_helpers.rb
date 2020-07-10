# frozen_string_literal: true

# Helpers for SQL functions testing
module Logidze
  module SqlHelpers
    # Generate a migration with the provided contents
    def migration(name, contents)
      successfully "rails generate migration #{name}"

      file = Dir.glob("db/migrate/*_#{name}.rb").first

      File.write(
        file,
        File.read(file).sub(/^\s+def change\s+end/m, contents)
      )
    end
  end
end
