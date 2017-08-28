# encoding: ASCII-8BIT

require 'logger'
require 'rainbow'

require 'pwnlib/context'

module Pwnlib
  # Logger module!
  module Logger
    # The type for logger. User should never need to initialize one by themself.
    class LoggerType < ::Logger
      SEV_COLOR = {
        'DEBUG' => 'red',
        'INFO' => 'blue',
        'WARN' => 'yellow',
        'ERROR' => 'red',
        'FATAL' => 'magenta'
      }.freeze

      def initialize
        super(STDOUT)
        self.formatter = proc do |severity, _datetime, _progname, msg|
          format("[%s] %s\n", Rainbow(severity).__send__(SEV_COLOR[severity]).bright, msg)
        end
      end

      # (XXX): Dont know how to use +context.log_level+ instead +@level+ in method +add+.
      def add(severity, message = nil, progname = nil)
        severity ||= UNKNOWN
        return true if @logdev.nil? || severity < context.log_level
        progname ||= @progname
        if message.nil?
          if block_given?
            message = yield
          else
            message = progname
            progname = @progname
          end
        end
        @logdev.write(
          format_message(format_severity(severity), Time.now, progname, message)
        )
        true
      end

      def indented(message, level: DEBUG)
        return if @logdev.nil? || level < context.log_level
        @logdev.write(
          message.lines.map { |s| '    ' + s }.join + "\n"
        )
        true
      end

      include ::Pwnlib::Context
    end

    @logger = LoggerType.new

    # @!attribute [r] logger
    #   @return [LoggerType] the singleton logger for all class.
    class << self
      attr_reader :logger
    end

    # A module for include hook for logger.
    # Including Pwnlib::Logger from module M would add +logger+ as a private instance method and a private class
    # method for module M.
    # @!visibility private
    module IncludeLogger
      private

      def logger
        ::Pwnlib::Logger.logger
      end
    end

    # @!visibility private
    def self.included(base)
      base.include(IncludeLogger)
      class << base
        include IncludeLogger
      end
    end

    include ::Logger::Severity
  end
end
