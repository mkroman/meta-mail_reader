# frozen_string_literal: true

require 'logging'

module Meta
  module MailReader
    class PostProcessor
      def self.id
        raise NotImplementedError
      end

      def self.media type
        @media = type
      end

      def self.processors
        @processors ||= []
      end

      def self.inherited klass
        @log ||= ::Logging.logger[self]
        @log.debug "Added postprocessor #{klass}"

        processors << klass
      end

      def initialize path
        @path = path
      end

      def run
        raise NotImplementedError
      end
    end
  end
end

Dir.glob(File.join(__dir__, 'post_processors/*.rb')).each do |file|
  require_relative file
end
