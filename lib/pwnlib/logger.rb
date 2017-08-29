# encoding: ASCII-8BIT

require 'logger'
require 'rainbow'

require 'pwnlib/context'

module Pwnlib
  # Logger module!
  module Logger
    # The type for logger which inherits Ruby builtin Logger.
    # We use +context.log_level+ instead of +@level+.
    class LoggerType < ::Logger
      SEV_COLOR = {
        'DEBUG' => '#ff5f5f',
        'INFO' => '#87ff00',
        'WARN' => '#ffff00',
        'ERROR' => '#ff5f00',
        'FATAL' => '#ff0000'
      }.freeze

      # Instantiate a {Pwnlib::Logger::LoggerType} object.
      def initialize
        super(STDOUT)
        # Set +@level+ to the lowest priority.
        @level = DEBUG
        @formatter = proc do |severity, _datetime, _progname, msg|
          format("[%s] %s\n", Rainbow(severity).color(SEV_COLOR[severity]), msg)
        end
      end

      # Log the message with indent.
      #
      # @param [String] message
      #   The message to log.
      # @param [DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN] level
      #   The severity of the message.
      def indented(message, level: DEBUG)
        return if @logdev.nil? || level < context.log_level
        @logdev.write(
          message.lines.map { |s| '    ' + s }.join + "\n"
        )
        true
      end

      private

      def add(severity, message = nil, progname = nil)
        severity ||= UNKNOWN
        return true if severity < context.log_level
        super(severity, message, progname)
      end

      include ::Pwnlib::Context
    end

    @log = LoggerType.new

    # @!attribute [r] logger
    #   @return [LoggerType] the singleton logger for all class.
    class << self
      attr_reader :log
    end

    # A module for include hook for logger.
    # Including Pwnlib::Logger from module M would add +log+ as a private instance method and a private class
    # method for module M.
    # @!visibility private
    module IncludeLogger
      private

      def log
        ::Pwnlib::Logger.log
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
