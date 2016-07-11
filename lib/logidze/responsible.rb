# frozen_string_literal: true
module Logidze # :nodoc:
  # Provide methods to work with "responsible user" feature
  module Responsible
    def with_responsible(responsible_id)
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute(
          "SET LOCAL logidze.responsible = #{ActiveRecord::Base.connection.quote(responsible_id)};"
        )
        res = yield
        ActiveRecord::Base.connection.execute "SET LOCAL logidze.responsible = DEFAULT;"
        res
      end
    end
  end
end