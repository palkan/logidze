# frozen_string_literal: true

module Logidze # :nodoc:
  # Provide methods to attach meta information
  module Meta
    def with_meta(meta, transactional: true, &block)
      wrapper = transactional ? MetaWithTransaction : MetaWithoutTransaction
      wrapper.wrap_with(meta, &block)
    end

    def with_responsible(responsible_id, transactional: true, &block)
      return yield if responsible_id.nil?

      meta = {Logidze::History::Version::META_RESPONSIBLE => responsible_id}
      with_meta(meta, transactional: transactional, &block)
    end

    class MetaWrapper # :nodoc:
      def self.wrap_with(meta, &block)
        new(meta, &block).perform
      end

      attr_reader :meta, :block

      delegate :connection, to: ActiveRecord::Base

      def initialize(meta, &block)
        @meta = meta
        @block = block
      end

      def perform
        raise ArgumentError, "Block must be given" unless block
        return block.call if meta.nil?

        call_block_in_meta_context
      end

      def call_block_in_meta_context
        prev_meta = current_meta

        meta_stack.push(meta)

        pg_set_meta_param(current_meta)
        result = block.call
        result
      ensure
        pg_reset_meta_param(prev_meta)
        meta_stack.pop
      end

      def current_meta
        meta_stack.reduce(:merge) || {}
      end

      def meta_stack
        Thread.current[:meta] ||= []
        Thread.current[:meta]
      end

      def encode_meta(value)
        connection.quote(ActiveSupport::JSON.encode(value))
      end

      def pg_reset_meta_param(prev_meta)
        if prev_meta.empty?
          pg_clear_meta_param
        else
          pg_set_meta_param(prev_meta)
        end
      end
    end

    class MetaWithTransaction < MetaWrapper # :nodoc:
      private

      def call_block_in_meta_context
        connection.transaction { super }
      end

      def pg_set_meta_param(value)
        connection.execute("SET LOCAL logidze.meta = #{encode_meta(value)};")
      end

      def pg_clear_meta_param
        connection.execute("SET LOCAL logidze.meta TO DEFAULT;")
      end
    end

    class MetaWithoutTransaction < MetaWrapper # :nodoc:
      private

      def pg_set_meta_param(value)
        connection.execute("SET logidze.meta = #{encode_meta(value)};")
      end

      def pg_clear_meta_param
        connection.execute("SET logidze.meta TO DEFAULT;")
      end
    end

    private_constant :MetaWrapper
    private_constant :MetaWithTransaction
    private_constant :MetaWithoutTransaction
  end
end
