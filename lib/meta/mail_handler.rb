# frozen_string_literal: true

module Meta
  # There was an error running one of the processing stages of a pipeline.
  class PipelineProcessError < StandardError; end
  class PipelineNotFoundError < StandardError; end

  class MailHandler
    VIDEO_MIME_TYPES = %w[video/mp4 video/webm video/quicktime
                          video/x-ms-asf].freeze
    IMAGE_MIME_TYPES = %w[image/jpeg image/png].freeze

    PIPELINES = {
      image: %i[image_exif_rotator exif_remover],
      video: %i[video_transcoder]
    }.freeze

    def initialize
      @log = Logging.logger[self]
      @s3 = Aws::S3::Client.new
      @rpc = Meta::RPC::Client.new 'tcp://localhost:31337', ENV['RPC_SECRET']
      @bucket_name = ENV['S3_BUCKET_NAME']
    end

    def send_chat_message message
      @rpc.connect

      params = {
        'network' => '*',
        'channel' => '#uplink',
        'message' => message
      }

      @rpc.call 'message', params
    end

    # Called by the +MailReader+ for each attachment in a newly received e-mail.
    #
    # @param [Mail::Message] mail the whole mail instance
    # @param [Mail::Attachment] attachment the attachment to process
    # @param [String] path the local file path to where the attached file is
    #   saved.
    def new_attachment mail, attachment, path
      file_type = determine_file_type path

      begin
        path = run_pipeline path, file_type
        result = upload_mail_attachment mail, attachment, path

        if result
          object = Aws::S3::Object.new @bucket_name, result, client: @s3
          url = object.public_url
          url = URI url

          url.host = 'mails.uplink.io'
          url.path = '/' + File.basename(url.path)

          sender = mail.from.join ', '

          @log.debug "File has been uploaded and can be accessed at #{url}"

          if mail.subject && !mail.subject.empty?
            send_chat_message "\x0310> “\x0f#{mail.subject}\x0310” from\x0f #{sender}\x0310 @ #{url}"
          else
            send_chat_message "\x0310>\x0f Mail\x0310 from #{sender}\x0310 @ #{url}"
          end
        end

      rescue PipelineNotFoundError
        @log.warn 'No related pipeline for the attachment found'
      ensure
        # Remove the local file.
        if File.exist? path
          @log.debug "Removing file `#{path}'"

          File.unlink path
        end
      end
    end

    def run_pipeline attachment_path, file_type
      pipeline = PIPELINES[file_type]

      unless pipeline
        raise PipelineNotFoundError, "Attachment #{attachment_path} was " \
          'neither audio nor video.'
      end

      processors = PIPELINES[file_type].map do |id|
        Meta::PostProcessor.processors.find { |p| p.id == id }
      end

      path = attachment_path

      processors.each do |processor_class|
        @log.debug "Instantiating postprocessor #{processor_class}"
        processor = processor_class.new path

        @log.debug "Running postprocessor #{processor}"
        path = processor.run
      end

      path
    end

    def upload_mail_attachment mail, attachment, attachment_path
      filename = File.basename attachment_path
      hexdigest = Digest::SHA256.file(attachment_path).hexdigest
      extension = File.extname filename
      remote_filename = "#{hexdigest}#{extension}"
      key = File.join 'mails', remote_filename

      @log.info "Uploading #{attachment_path} to bucket #{@bucket_name} with the key #{key}"

      begin
        object = @s3.head_object bucket: @bucket_name, key: key

        @log.debug 'The remote file already exists - skipping upload'
      rescue Aws::S3::Errors::Forbidden
        # The file doesn't already exist, so we'll upload it
        File.open attachment_path, 'rb' do |file|
          object = @s3.put_object body: file,
                                  acl: 'public-read',
                                  bucket: @bucket_name,
                                  key: key
        end
      end

      return nil unless object

      key
    end

    # Determines the file type of the file at +path+ and returns the type as a
    # symbol, or nil if unsupported.
    #
    # # @return [Symbol, nil] the type as symbol or nil if unsupported
    def determine_file_type path
      mime_type = Magic.guess_file_mime_type path

      return :video if VIDEO_MIME_TYPES.include? mime_type
      return :image if IMAGE_MIME_TYPES.include? mime_type

      nil
    end

  end
end
