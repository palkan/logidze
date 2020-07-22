# frozen_string_literal: true

module Logidze
  module Generators
    module InjectSql
      def inject_sql(source, indent: 4)
        source = ::File.expand_path(find_in_source_paths(source.to_s))

        indent(
          ERB.new(::File.binread(source)).tap do |erb|
            erb.filename = source
          end.result(instance_eval("binding")), # rubocop:disable Style/EvalWithLocation
          indent
        )
      end
    end
  end
end
