# frozen_string_literal: true

module Logidze
  module Generators
    # Adds --fx option and provide #fx? method
    module FxHelper
      def self.included(base)
        base.class_option :fx, type: :boolean, optional: true,
          desc: "Define whether to use fx gem functionality"
      end

      def fx?
        options[:fx] || (options[:fx] != false && defined?(::Fx::SchemaDumper))
      end
    end
  end
end
