# frozen_string_literal: true
#
require 'shellwords'
require 'digest/sha2'
require 'securerandom'

require 'nanoid'
require 'magic'
require 'mail'
require 'logging'
require 'streamio-ffmpeg'
require 'aws-sdk-s3'

# Set up logging
Logging.color_scheme(
  'meta',
  levels: {
    debug: :white,
    info: :cyan,
    warn: :yellow,
    error: :red,
    fatal: :orange
  },
  date: :white,
  logger: %i[white bold],
  message: :white
)

Logging.appenders.stdout(
  'stdout',
  layout: Logging.layouts.pattern(
    pattern: '%d %-16.16c %-5l %m\n',
    date_pattern: '%Y-%m-%d %H:%M:%S',
    color_scheme: 'meta'
  )
)

Logging.logger.root.level = :debug
Logging.logger.root.appenders = Logging.appenders.stdout

module Meta
  module MailReader
    # There was an error running one of the processing stages of a pipeline.
    class PipelineProcessError < StandardError; end
    class PipelineNotFoundError < StandardError; end
  end
end

require_relative './mail_reader/client'
require_relative './mail_reader/attachment'
require_relative './mail_reader/attachment_list'
require_relative './mail_reader/handler'
require_relative './mail_reader/post_processor'
require_relative './mail_reader/version'
