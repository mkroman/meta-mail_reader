# frozen_string_literal: true

module Meta
  module MailReader
    # Class that wraps interactions with an AWS S3 bucket
    class Bucket
      # @return [String] the bucket name
      attr_accessor :name

      ATTACHMENT_PATH_PREFIX = 'mails'

      # Creates a new +Bucket+.
      def initialize name
        @log = Logging.logger[self]
        @name = name
        @client = Aws::S3::Client.new
      end

      def upload_attachment file_path
        remote_filename = generate_remote_filename file_path
        key = File.join ATTACHMENT_PATH_PREFIX, remote_filename

        if file_exists? remote_filename
          # Don't do anything
        else
          @log.info "Uploading #{file_path} to bucket #{@name} with the key #{key}"

          upload_file file_path, remote_filename
        end
      end

      # Uploads the local file at +file_path+ to the bucket, saving it under the
      # key +key+.
      def upload_file file_path, key
        File.open file_path, 'rb' do |file|
          @client.put_object key: key,
                             acl: 'public-read',
                             body: file,
                             bucket: @name
        end
      end

      # Returns whether the given +key+ exists as an object in the bucket.
      def file_exists? key
        !@client.head_object(key: key, bucket: @name).nil?
      rescue Aws::S3::Errors::Forbidden
        false
      end

      # Generates a reproducible filename by digesting the contents of the file
      # with SHA256 and returns it as a decimal string suffixed by the file
      # extension.
      def generate_remote_filename file_path
        hexdigest = Digest::SHA256.file(file_path).hexdigest
        extension = File.extname File.basename file_path

        "#{hexdigest}#{extension}"
      end
    end
  end
end
