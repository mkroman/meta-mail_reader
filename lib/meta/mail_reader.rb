# frozen_string_literal: true

module Meta
  class MailReader
    # The maximum amount of attachments we will process per e-mail.
    MAX_ATTACHMENT_COUNT = 10

    def initialize attachment_root_dir:
      @log = Logging.logger[self]
      @callbacks = {}
      @attachment_root_dir = attachment_root_dir

      @log.info "MailReader version #{Meta::VERSION}"
      @log.debug "Attachments will be saved in `#{attachment_root_dir}'"
    end

    def on event, &block
      (@callbacks[event] ||= []) << block
    end

    # Polls the inbox for new e-mails, yields them in the related callbacks and
    # then deletes them.
    def poll
      Mail.find_and_delete do |mail|
        attachment_count = mail.attachments.count

        if attachment_count.zero?
          @log.info "Skipping e-mail #{mail.subject} from #{mail.from} as " \
            'this e-mail has no attachments'
          next
        end

        @log.info "Received e-mail #{mail.subject} from #{mail.from} with " \
          "#{mail.attachments.count} attachments"

        process_mail mail
      end
    end

    def process_mail mail
      mail.attachments.slice(0...MAX_ATTACHMENT_COUNT).each do |attachment|
        process_mail_attachment mail, attachment
      end
    end

    def process_mail_attachment mail, attachment
      attachment_path = save_attachment attachment
      @log.debug "Saved attachment as #{attachment_path}"

      emit :attachment, mail, attachment, attachment_path
    rescue StandardError => error
      @log.error 'Failed to process attachment!'
      @log.error error
    end

    # Writes the attachment body to temporary storage and then yields the file
    # path.
    def save_attachment attachment
      filename = sanitize_filename attachment.filename
      path = File.join @attachment_root_dir, filename

      File.open path, 'w+b', 0o644 do |file|
        file.write attachment.body.decoded
      end

      yield path if block_given?
      path
    end

    private

    def sanitize_filename filename
      filename.gsub(/[^a-zA-Z0-9\-_\.]+/, '')
    end

    def emit event, *args
      @callbacks[event].each { |p| p.call *args }
    end
  end
end
