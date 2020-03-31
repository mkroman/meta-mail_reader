# frozen_string_literal: true

module Meta
  module MailReader
    module PostProcessors
      class VideoTranscoder < PostProcessor
        def self.id
          :video_transcoder
        end

        def run
          dirname = File.dirname @path
          filename = File.basename @path, '.*'
          extension = File.extname @path

          output_path = if extension == '.mp4'
                          File.join dirname, "#{filename}-2.mp4"
                        else
                          File.join dirname, "#{filename}.mp4"
                        end

          movie = FFMPEG::Movie.new @path

          video_codec = 'copy'
          audio_codec = 'copy'

          video_codec = 'h264' if movie.video_codec != 'h264'
          audio_codec = 'aac' if movie.audio_codec != 'aac'

          movie.transcode output_path, video_codec: video_codec,
                                       audio_codec: audio_codec

          # Remove the old video file.
          File.unlink @path
          @path = output_path

          output_path
        end
      end
    end
  end
end
