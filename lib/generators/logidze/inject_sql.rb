# frozen_string_literal: true

module Logidze
  module Generators
    module InjectSql
      def inject_sql(source)
        source = ::File.expand_path(find_in_source_paths(source.to_s))

        ERB.new(::File.binread(source)).tap do |erb|
          erb.filename = source
        end.result(instance_eval("binding")) # rubocop:disable Style/EvalWithLocation
      end
    end
  end
end
