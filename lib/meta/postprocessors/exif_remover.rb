# frozen_string_literal: true

module Meta
  module PostProcessors
    class ExifRemover < PostProcessor
      media :image

      def run
        `exiv2 rm "#{@path}"`

        @path
      end
    end
  end
end

