# frozen_string_literal: true

module Meta
  module MailReader
    # AttachmentList is a list of attached files that have been written to disk
    # for further processing.
    class AttachmentList
      def initialize(*args)
        @files = []
      end
    end
  end
end

