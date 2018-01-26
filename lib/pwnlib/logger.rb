# encoding: ASCII-8BIT

require 'binding_of_caller'
require 'logger'
require 'method_source'
require 'rainbow'
require 'ruby2ruby'
require 'ruby_parser'

require 'pwnlib/context'

module Pwnlib
  # Logging module for printing status during an exploitation, and internally within {Pwnlib}.
  #
  # An exploit developer can use +log+ to print out status messages during an exploitation.
  module Logger
    # The type for logger which inherits Ruby builtin Logger.
    # Main difference is using +context.log_level+ instead of +level+ in logging methods.
    class LoggerType < ::Logger
      # Color codes for pretty logging.
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
        @formatter = proc do |severity, _datetime, progname, msg|
          format("[%s] %s\n", Rainbow(progname || severity).color(SEV_COLOR[severity]), msg)
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

      # Log the string and its evaluated result.
      #
      # This method has same severity as +INFO+.
      #
      # @param [Array<String>] args
      #   The strings to be evaluated.
      #
      # @yieldreturn [Object]
      #   See examples.
      #   Block will be invoked only if +args+ is empty.
      #
      # @return See ::Logger#add.
      #
      # @example
      #   x = 2
      #   y = 3
      #   log.dump('x + y', 'x * y')
      #   # [DUMP] x + y = 5, x * y = 6
      # @example
      #   libc = 0x7fc0bdd13000
      #   log.dump { libc.hex }
      #   # [DUMP] libc.hex = "0x7fc0bdd13000"
      #   log.dump { libc = 12345678; libc.hex }
      #   # [DUMP] libc = 12345678
      #   #        libc.hex = "0xbc614e"
      #
      # @note
      #   This method doesn't work in a REPL shell.
      #
      # @note
      #   The source code in block will be parsed using +ruby_parser+,
      #   therefore this method fails in some situations, such as:
      #     log.dump(&something) # will fail in souce code parsing
      #     log.dump { 1 }; log.dump { 2 } # 1 will be logged two times
      def dump(*args, &block)
        severity = INFO
        # Don't invoke the block if it's unnecessary.
        return true if severity < context.log_level
        exprs = args.empty? ? Array(parse_proc(block)) : args
        ctx = binding.of_caller(1)
        msg = exprs.map { |expr| "#{expr.strip} = #{ctx.eval(expr).inspect}" }.join(', ')
        # do indent if msg contains multiple lines
        first, *remain = msg.split("\n")
        add(severity, ([first] + remain.map { |r| '[DUMP] '.gsub(/./, ' ') + r }).join("\n"), 'DUMP')
      end

      private

      def add(severity, message = nil, progname = nil)
        severity ||= UNKNOWN
        return true if severity < context.log_level
        super(severity, message, progname)
      end

      # This method do the following things:
      #   1. Get the source code from file (using gem `method_source`)
      #   2. Parse the source code to Sexp using `ruby_parser`
      #   3. Traverse the sexp and find the block argument when calling `:dump`
      #   4. Convert the sexp back to Ruby code (using gem `ruby2ruby`)
      #
      # @param [Proc] process
      #
      # @return [String]
      def parse_proc(process)
        # XXX(david942j): move this method to another place?

        # source might contain other 'dirty' things,
        # use ruby parser to fetch the true code inside block.
        src = process.source
        sexp = RubyParser.new.process(src)
        # XXX(david942j): don't hardcode the target
        sexp = search_sexp(sexp, [:iter, [:call, nil, :dump]]) || []
        Ruby2Ruby.new.process(sexp.last)
      end

      def search_sexp(sexp, target)
        return nil unless sexp.is_a?(::Sexp)
        return sexp if match_sexp?(sexp, target)
        sexp.find do |e|
          f = search_sexp(e, target)
          break f if f
        end
      end

      def match_sexp?(sexp, target)
        target.zip(sexp.entries).all? do |t, s|
          next true if t.nil?
          next match_sexp?(s, t) if t.is_a?(Array)
          s == t
        end
      end

      include ::Pwnlib::Context
    end

    @log = LoggerType.new

    # @!attribute [r] logger
    #   @return [LoggerType] the singleton logger for all classes.
    class << self
      attr_reader :log
    end

    # Include this module to use logger.
    # Including {Pwnlib::Logger} from module M would add +log+ as a private instance method and a private class
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
