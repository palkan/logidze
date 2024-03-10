# frozen_string_literal: true

module Logidze # :nodoc:
  module ConnectionAdapter
    module ActiveRecord
    end

    module Sequel
    end

    # Provide API interface to manipulate Logidze database settings and attach meta information
    module Base
      # Temporary disable DB triggers (default connection adapter).
      #
      # @example
      #   Logidze[:active_record].without_logging { Post.update_all(active: true) }
      def without_logging(&block)
        with_logidze_setting("logidze.disabled", "on") { yield }
      end

      # Instruct Logidze to create a full snapshot for the new versions, not a diff.
      #
      # @example
      #   Logidze[:active_record].with_full_snapshot { post.touch }
      def with_full_snapshot(&block)
        with_logidze_setting("logidze.full_snapshot", "on") { yield }
      end

      # Store any meta information inside the version (it could be IP address, user agent, etc.)
      #
      # @example
      #   Logidze[:active_record].with_meta({ip: request.ip}) { post.save! }
      def with_meta(meta, transactional: true, &block)
        wrapper = transactional ? MetaWithTransaction : MetaWithoutTransaction
        wrapper.wrap_with(self, meta, &block)
      end

      # Store special meta information about changes' author inside the version (Responsible ID).
      # Usually, you would like to store the `current_user.id` that way
      #
      # @example
      #   Logidze[:active_record].with_responsible(user.id) { post.save! }
      def with_responsible(responsible_id, transactional: true, &block)
        return yield if responsible_id.nil?

        meta = {Logidze::History::Version::META_RESPONSIBLE => responsible_id}
        with_meta(meta, transactional: transactional, &block)
      end

      private

      def with_logidze_setting(name, value, &block)
        transaction do
          execute "SET LOCAL #{name} TO #{value};"
          res = yield
          execute "SET LOCAL #{name} TO DEFAULT;"
          res
        end
      end

      class MetaWrapper # :nodoc:
        def self.wrap_with(connection_adapter, meta, &block)
          new(connection_adapter, meta, &block).perform
        end

        attr_reader :connection_adapter, :meta, :block

        def initialize(connection_adapter, meta, &block)
          @connection_adapter = connection_adapter
          @meta = meta
          @block = block
        end

        def perform
          raise ArgumentError, "Connection adapter must be choosen" unless connection_adapter
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
          connection_adapter.encode_meta(value)
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
          connection_adapter.transaction { super }
        end

        def pg_set_meta_param(value)
          connection_adapter.execute("SET LOCAL logidze.meta = #{encode_meta(value)};")
        end

        def pg_clear_meta_param
          connection_adapter.execute("SET LOCAL logidze.meta TO DEFAULT;")
        end
      end

      class MetaWithoutTransaction < MetaWrapper # :nodoc:
        private

        def pg_set_meta_param(value)
          connection_adapter.execute("SET logidze.meta = #{encode_meta(value)};")
        end

        def pg_clear_meta_param
          connection_adapter.execute("SET logidze.meta TO DEFAULT;")
        end
      end

      private_constant :MetaWrapper
      private_constant :MetaWithTransaction
      private_constant :MetaWithoutTransaction
    end
  end
end
