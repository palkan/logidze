# frozen_string_literal: true

module Logidze
  module Generators
    # Adds --sequel option and provides #sequel? method
    module SequelHelper
      def self.included(base)
        base.class_option :sequel, type: :boolean, optional: true,
          desc: "Define whether to generate Sequel install migrations"
      end

      def sequel?
        options.fetch(:sequel, false)
      end
    end
  end
end
