# frozen_string_literal: true

module Meta
  module MailReader
    # +Attachment+ holds information about an e-mail attachment and its upload
    # state.
    class Attachment
      def initialize
        @uploaded = false
        @processed = false
      end
    end
  end
end
