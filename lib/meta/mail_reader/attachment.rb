# frozen_string_literal: true

module Meta
  module MailReader
    # +Attachment+ holds information about an e-mail attachment and its upload
    # state. It is the job of the Attachment to remove the local file.
    class Attachment

      def initialize file_path
        @file_path = file_path
        @uploaded = false
        @processed = false
      end
    end
  end
end
