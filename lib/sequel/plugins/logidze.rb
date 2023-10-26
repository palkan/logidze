# frozen_string_literal: true

require "sequel/model"

require "logidze"
require "logidze/history/serializer"

module Sequel
  module Plugins
    # A standard Sequel plugin which replicates `has_logidze` method from ActiveRecord
    module Logidze
      def self.configure(model, opts = {})
        model.instance_eval do
          @ignore_log_data = opts.fetch(:ignore_log_data) do
            ::Logidze.ignore_log_data_by_default
          end

          if @ignore_log_data
            plugin :lazy_attributes, :log_data
            plugin :insert_returning_select
          end
        end
      end

      module DatasetMethods
        include ::Logidze::Model::ClassMethods

        def logidze_adapter
          ::Logidze::Model::Sequel
        end

        def ignores_log_data?
          @ignore_log_data
        end

        def with_log_data
          all_selectd_columns = columns.map { |column| Sequel.qualify(first_source, column) }
          selected_columns = opts[:select]

          if all_selectd_columns == selected_columns
            select_all
          else
            select(*selected_columns + [Sequel.qualify(first_source, :log_data)])
          end
        end
      end

      module ClassMethods
        Sequel::Plugins.def_dataset_methods(self, %i[
          logidze_adapter
          ignores_log_data?
          with_log_data
          has_logidze
          at
          diff_from
          without_logging
          reset_log_data
          create_logidze_snapshot
        ])
        Sequel::Plugins.inherited_instance_variables(self, :@ignore_log_data => :dup)
      end

      module InstanceMethods
        include ::Logidze::Model

        def logidze_adapter
          @logidze_adapter ||= ::Logidze::Model::Sequel.new(self)
        end

        # TODO: use `serialization` plugin later as it seems the setter doesn't work without reload.
        def log_data
          @deserialized_log_data ||= ::Logidze::History::Serializer.deserialize(self[:log_data])
        end

        def log_data=(value)
          self[:log_data] = ::Logidze::History::Serializer.serialize(value)
          @deserialized_log_data = nil
          log_data
        end

        # Called on `dup`.
        def initialize_copy(other)
          super
          self.log_data = other.log_data.dup
          self
        end

        # Called on model's manual find.
        def _refresh_set_values(values)
          result = super
          @deserialized_log_data = nil
          result
        end

        # Called on model's auto find.
        def _save_set_values(values)
          result = super
          @deserialized_log_data = nil
          result
        end
      end
    end
  end
end
