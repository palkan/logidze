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

    def with_meta!(meta)
      return if meta.nil?

      if Thread.current[:logidze_in_block]
        raise StandardError, "with_meta! cannot be called from within a with_meta block"
      end

      MetaForConnection.new(meta).set!
    end

    def clear_meta!
      MetaForConnection.new({}).clear!
    end

    def with_responsible!(responsible_id)
      return if responsible_id.nil?

      meta = {Logidze::History::Version::META_RESPONSIBLE => responsible_id}
      with_meta!(meta)
    end

    def clear_responsible!
      clear_meta!
    end

    class MetaBase # :nodoc:
      attr_reader :meta

      delegate :connection, to: ActiveRecord::Base

      def initialize(meta)
        @meta = meta
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

    class MetaWrapper < MetaBase # :nodoc:
      def self.wrap_with(meta, &block)
        new(meta, &block).perform
      end

      attr_reader :block

      def initialize(meta, &block)
        super(meta)
        @block = block
      end

      def perform
        raise ArgumentError, "Block must be given" unless block
        return block.call if meta.nil?

        call_block_in_meta_context
      end

      def call_block_in_meta_context
        prev_meta = current_meta
        was_in_block = Thread.current[:logidze_in_block]

        meta_stack.push(meta)
        Thread.current[:logidze_in_block] = true

        pg_set_meta_param(current_meta)
        result = block.call
        result
      ensure
        pg_reset_meta_param(prev_meta)
        meta_stack.pop
        Thread.current[:logidze_in_block] = was_in_block
      end
    end

    class MetaForConnection < MetaBase # :nodoc:
      def set!
        return if meta.nil?

        meta_stack.push(meta)
        pg_set_meta_param(current_meta)
      end

      def clear!
        meta_stack.clear
        pg_clear_meta_param
      end

      private

      def pg_set_meta_param(value)
        connection.execute("SET logidze.meta = #{encode_meta(value)};")
      end

      def pg_clear_meta_param
        connection.execute("SET logidze.meta TO DEFAULT;")
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

    private_constant :MetaBase
    private_constant :MetaWrapper
    private_constant :MetaForConnection
    private_constant :MetaWithTransaction
    private_constant :MetaWithoutTransaction
  end
end
