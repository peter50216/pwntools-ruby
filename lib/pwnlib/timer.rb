# encoding: ASCII-8BIT

require 'time'

require 'pwnlib/context'
require 'pwnlib/errors'

module Pwnlib
  # A simple timer class.
  # TODO(Darkpi): Python pwntools seems to have many unreasonable codes in this class,
  #               not sure of the use case of this, check if everything is coded as
  #               intended after we have some use cases. (e.g. sock)
  # NOTE(Darkpi): This class is actually quite weird, and expected to be used only in tubes.
  class Timer
    # @diff We just use nil for default and :forever for forever.

    def initialize(timeout = nil)
      @deadline = nil
      @timeout = timeout
    end

    def started?
      @deadline
    end

    def active?
      started? && (@deadline == :forever || Time.now < @deadline)
    end

    def timeout
      return @timeout || ::Pwnlib::Context.context.timeout unless started?
      @deadline == :forever ? :forever : [@deadline - Time.now, 0].max
    end

    def timeout=(timeout)
      raise "Can't change timeout when countdown" if started?
      @timeout = timeout
    end

    # @diff We do NOT allow nested countdown with non-default value. This simplifies thing a lot.
    # NOTE(Darkpi): timeout = nil means default value for the first time, and nop after that.
    def countdown(timeout = nil)
      raise ArgumentError, 'Need a block for countdown' unless block_given?
      if started?
        return yield if timeout.nil?
        raise 'Nested countdown not permitted'
      end

      timeout ||= @timeout
      timeout ||= ::Pwnlib::Context.context.timeout

      @deadline = timeout == :forever ? :forever : Time.now + timeout

      begin
        yield
      ensure
        raise ::Pwnlib::Errors::TimeoutError unless active?.tap { @deadline = nil }
      end
    end
  end
end
