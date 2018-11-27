# frozen_string_literal: true

module Logidze
  module IgnoreLogData
    # Backports ignored_columns functionality to Rails < 5
    module IgnoredColumns
      module Base # :nodoc:
        attr_writer :ignored_columns

        def ignored_columns
          @ignored_columns ||= []
        end
      end

      module Relation # :nodoc:
        private

        def build_select(arel)
          if select_values.blank? && klass.ignored_columns.any?
            arel.project(*arel_columns(klass.column_names - klass.ignored_columns))
          else
            super
          end
        end
      end

      module Table # :nodoc:
        def columns
          super.reject { |column| ignored_columns.include?(column.name) }
        end

        private

        def ignored_columns
          node.base_klass.ignored_columns
        end
      end
    end
  end
end

ActiveRecord::Base.extend(Logidze::IgnoreLogData::IgnoredColumns::Base)
ActiveRecord::Relation.include(Logidze::IgnoreLogData::IgnoredColumns::Relation)
ActiveRecord::Associations::JoinDependency::Aliases::Table.prepend(
  Logidze::IgnoreLogData::IgnoredColumns::Table
)
