# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'logger'

require 'method_source/code_helpers' # don't require 'method_source', it pollutes Method/Proc classes.
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
      # To use method +expression_at+.
      #
      # XXX(david942j): move this extension if other modules need +expression_at+ as well.
      extend ::MethodSource::CodeHelpers

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

      # Log the arguments and their evalutated results.
      #
      # This method has same severity as +INFO+.
      #
      # The difference between using arguments and passing a block is the block will be executed if the logger's level
      # is sufficient to log a message.
      #
      # @param [Array<#inspect>] args
      #   Anything. See examples.
      #
      # @yieldreturn [#inspect]
      #   See examples.
      #   Block will be invoked only if +args+ is empty.
      #
      # @return See ::Logger#add.
      #
      # @example
      #   x = 2
      #   y = 3
      #   log.dump(x + y, x * y)
      #   # [DUMP] (x + y) = 5, (x * y) = 6
      # @example
      #   libc = 0x7fc0bdd13000
      #   log.dump libc.hex
      #   # [DUMP] libc.hex = "0x7fc0bdd13000"
      #
      #   libc = 0x7fc0bdd13000
      #   log.dump { libc.hex }
      #   # [DUMP] libc.hex = "0x7fc0bdd13000"
      #   log.dump { libc = 12345678; libc.hex }
      #   # [DUMP] libc = 12345678
      #   #        libc.hex = "0xbc614e"
      # @example
      #   log.dump do
      #     meow = 123
      #     # comments will be ignored
      #     meow <<= 1 # this is a comment
      #     meow
      #   end
      #   # [DUMP] meow = 123
      #   #        meow = (meow << 1)
      #   #        meow = 246
      #
      # @note
      #   This method does NOT work in a REPL shell (such as irb and pry).
      #
      # @note
      #   The source code where invoked +log.dump+ will be parsed by using +ruby_parser+,
      #   therefore this method fails in some situations, such as:
      #     log.dump(&something) # will fail in souce code parsing
      #     log.dump { 1 }; log.dump { 2 } # 1 will be logged two times
      def dump(*args)
        severity = INFO
        # Don't invoke the block if it's unnecessary.
        return true if severity < context.log_level

        caller_ = caller_locations(1, 1).first
        src = source_of(caller_.absolute_path, caller_.lineno)
        results = args.empty? ? [[yield, source_of_block(src)]] : args.zip(source_of_args(src))
        msg = results.map { |res, expr| "#{expr.strip} = #{res.inspect}" }.join(', ')
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

      def source_of(path, line_number)
        @source_of_file_cache = Hash.new do |h, key|
          h[key] = IO.read(key)
        end
        f = @source_of_file_cache[path]
        LoggerType.expression_at(f, line_number)
      end

      # Find the content of block that invoked by log.dump { ... }.
      #
      # @param [String] source
      #
      # @return [String]
      #
      # @example
      #   source_of_block("log.dump do\n123\n456\nend")
      #   #=> "123\n456\n"
      def source_of_block(source)
        parse_and_search(source, [:iter, [:call, nil, :dump]]) { |sexp| ::Ruby2Ruby.new.process(sexp.last) }
      end

      # Find the arguments passed to log.dump(...).
      #
      # @param [String] source
      #
      # @return [Array<String>]
      #
      # @example
      #   source_of_args("log.dump(x, y, x + y)")
      #   #=> ["x", "y", "(x + y)"]
      def source_of_args(source)
        parse_and_search(source, [:call, nil, :dump]) do |sexp|
          sexp[3..-1].map { |s| ::Ruby2Ruby.new.process(s) }
        end
      end

      # This method do the following things:
      #   1. Parse the source code to `Sexp` (using `ruby_parser`)
      #   2. Traverse the sexp to find the block/arguments (according to target) when calling `dump`
      #   3. Convert the sexp of block back to Ruby code (using gem `ruby2ruby`)
      #
      # @yieldparam [Sexp] sexp
      #   The found Sexp according to +target+.
      def parse_and_search(source, target)
        sexp = ::RubyParser.new.process(source)
        sexp = search_sexp(sexp, target)
        return nil if sexp.nil?

        yield sexp
      end

      # depth-first search
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
