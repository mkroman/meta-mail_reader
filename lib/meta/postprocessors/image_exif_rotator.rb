# frozen_string_literal: true

module Meta
  module PostProcessors
    class ImageExifRotator < PostProcessor
      media :image

      def run
        `exiv2 rm "#{@path}"`

        @path
      end
    end
  end
end

