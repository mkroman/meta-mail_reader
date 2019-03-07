# frozen_string_literal: true

module Meta
  class PostProcessor
    def self.media type
      @media = type
    end

    def self.processors
      @processors ||= []
    end

    def self.included klass
      @log ||= Logging.logger[self]
      @log.debug "Added postprocessor #{klass}"

      processors << klass
    end

    def initialize path
      @path = path
    end

    def run
    end
  end
end


