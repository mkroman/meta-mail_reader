# frozen_string_literal: true

module Meta
  module MailReader
    module PostProcessors
      class ImageExifRotator < PostProcessor
        def initialize path
          @log = Logging.logger[self]
          super
        end

        def self.id
          :image_exif_rotator
        end

        media :image

        def run
          filename = Shellwords.escape @path

          @log.info "Rotating image #{@path}"

          `exiftran -i -a "#{filename}"`

          @path
        end
      end
    end
  end
end
