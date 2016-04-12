# encoding: ASCII-8BIT
require 'time'
# XXX(Darkpi): This actually is circular require, but seems to work fine?
#              Check if there's any problem with this.
require 'pwnlib/context'

module Pwnlib
  # Mixin module for class with timeout.
  # TODO(Darkpi): Python pwntools seems to have many unreasonable codes in this class,
  #               not sure of the use case of this, check if everything is coded as intended
  #               after we have some use cases. (e.g. sock)
  module Timeout
    # Difference from Python pwntools:
    # We just use default argument and :forever for forever.
    FOREVER = (2**20).to_f

    def initialize(timeout = nil)
      @stop = nil
      timeout ||= Pwnlib::Context.context.timeout
      self.timeout = timeout
    end

    def self.to_sec(timeout)
      case timeout
      when :forever then FOREVER
      else
        timeout = timeout.to_f
        raise ArgumentError, 'Timeout cannot be negative' if timeout < 0
        [timeout, FOREVER].min
      end
    end

    def timeout
      return @timeout unless @stop
      [@stop - Time.now, 0].max
    end

    def timeout=(timeout)
      @timeout = Timeout.to_sec(timeout)
      timeout_changed
    end

    def timeout_changed
    end

    def countdown_active?
      # XXX(Darkpi): Why should @stop == nil count as active??? (This is the case in Python pwntool)
      @stop && Time.now < @stop
    end

    def countdown(timeout = nil)
      raise ArgumentError, 'Need a block for countdown' unless block_given?
      timeout ||= @timeout
      return yield if timeout >= FOREVER

      old_timeout = @timeout
      old_stop = @stop

      @stop = Time.now + timeout
      @stop = [@stop, old_stop].min if old_stop
      begin
        self.timeout = timeout
        yield
      ensure
        @stop = old_stop
        self.timeout = old_timeout
      end
    end

    def local(timeout)
      raise ArgumentError, 'Need a block for countdown' unless block_given?
      old_timeout = @timeout
      old_stop = @stop

      @stop = nil
      begin
        self.timeout = timeout
        yield
      ensure
        @stop = old_stop
        self.timeout = old_timeout
      end
    end
  end
end
