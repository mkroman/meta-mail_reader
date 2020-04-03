# frozen_string_literal: true

module Meta
  module MailReader
    class Client
      # The maximum amount of attachments we will process per e-mail.
      MAX_ATTACHMENT_COUNT = 10

      # Creates a new Client
      def initialize attachment_root_dir:
        @log = Logging.logger[self]
        @handler = Handler.new
        @attachment_root_dir = attachment_root_dir

        @log.info "MailReader version #{Meta::MailReader::VERSION}"
        @log.debug "Attachments will be saved in `#{attachment_root_dir}'"
      end

      # Polls the inbox for new e-mails, yields them in the related callbacks and
      # then deletes them.
      def poll
        Mail.find_and_delete do |mail|
          attachment_count = mail.attachments.count

          if attachment_count.zero?
            @log.info "Skipping e-mail #{mail.subject} from #{mail.from} as " \
              'it has no attachments'
            next
          end

          @log.info "Received e-mail #{mail.subject} from #{mail.from} with " \
            "#{attachment_count} attachments"

          process_mail mail
        end
      end

      # Processes the given +mail+ and its attachments.
      def process_mail mail
        mail.attachments.slice(0...MAX_ATTACHMENT_COUNT).map do |attachment|
          attachment_path = save_attachment_to_disk attachment

          Attachment.new attachment_path
        end
      end

      # Writes the attachment body to temporary storage and then returns the
      # file path.
      def save_attachment_to_disk attachment
        filename = sanitize_filename attachment.filename
        path = File.join @attachment_root_dir, filename

        File.open path, 'w+b', 0o644 do |file|
          file.write attachment.body.decoded
        end

        path
      end

      private

      def sanitize_filename filename
        filename.gsub(/[^a-zA-Z0-9\-_\.]+/, '')
      end
    end
  end
end
