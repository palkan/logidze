# frozen_string_literal: true

module Logidze # :nodoc:
  # Provide methods to attach meta information
  module Meta
    def with_meta(meta, transactional: true, &block)
      return MetaWithTransaction.wrap_with(meta, &block) if transactional

      MetaWithoutTransaction.wrap_with(meta, &block)
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
    end

    class MetaWithTransaction < MetaWrapper # :nodoc:
      def perform
        return if block.nil?
        return block.call if meta.nil?

        ActiveRecord::Base.transaction { call_block_in_meta_context }
      end

      private

      def pg_set_meta_param(value)
        connection.execute("SET LOCAL logidze.meta = #{encode_meta(value)};")
      end

      def pg_reset_meta_param(prev_meta)
        if prev_meta.empty?
          connection.execute("SET LOCAL logidze.meta TO DEFAULT;")
        else
          pg_set_meta_param(prev_meta)
        end
      end

      def call_block_in_meta_context
        prev_meta = current_meta

        meta_stack.push(meta)

        pg_set_meta_param(current_meta)
        result = block.call
        pg_reset_meta_param(prev_meta)

        result
      ensure
        meta_stack.pop
      end
    end

    class MetaWithoutTransaction < MetaWrapper # :nodoc:
      def perform
        raise ArgumentError, "Block must be given" unless block

        call_block_in_meta_context
      end

      private

      def pg_set_meta_param(value)
        connection.execute("SET logidze.meta = #{encode_meta(value)};")
      end

      def pg_reset_meta_param(prev_meta)
        if prev_meta.empty?
          connection.execute("SET logidze.meta TO DEFAULT;")
        else
          pg_set_meta_param(prev_meta)
        end
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
    end

    private_constant :MetaWrapper
    private_constant :MetaWithTransaction
    private_constant :MetaWithoutTransaction
  end
end
