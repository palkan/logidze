# frozen_string_literal: true

module Logidze
  module IgnoreLogData
    # Since Rails caches ignored_columns, we have to patch .column_names and
    # .unscoped methods to make conditional log_data loading possible
    module DefaultScopePatch
      extend ActiveSupport::Concern

      class_methods do
        def column_names
          ignores_log_data? ? super : super + ["log_data"]
        end

        def unscoped
          if ignores_log_data?
            super
          else
            block_given? ? with_log_data.scoping { yield } : with_log_data
          end
        end
      end
    end
  end
end
