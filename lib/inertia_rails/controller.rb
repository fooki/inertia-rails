require_relative "inertia_rails"

module InertiaRails
  module Controller
    extend ActiveSupport::Concern

    included do
      class_attribute :shared_plain_data, default: {}
      class_attribute :shared_blocks, default: []
    end

    class_methods do
      def inertia_share(hash = nil, &block)
        share_plain_data(hash) if hash
        share_block(&block) if block_given?
      end

      private

      def share_plain_data(hash)
        self.shared_plain_data = shared_plain_data.merge(hash)
      end

      def share_block(&block)
        self.shared_blocks = shared_blocks + [ block ]
      end
    end

    def shared_data
      shared_plain_data.merge(evaluated_blocks)
    end

    private

    def evaluated_blocks
      shared_blocks.map { |block| instance_exec(&block) }.reduce(&:merge) || {}
    end
  end
end
