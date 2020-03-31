# frozen_string_literal: true

module Meta
  module MailReader
    module PostProcessors
      class ExifRemover < PostProcessor
        media :image

        def initialize path
          @log = Logging.logger[self]
          super
        end

        def self.id
          :exif_remover
        end

        def run
          @log.info "Stripping EXIF data from #{@path}"

          `exiv2 rm "#{@path}"`

          @path
        end
      end
    end
  end
end
