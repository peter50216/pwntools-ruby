# encoding: ASCII-8BIT
require 'time'
require 'pwnlib/context'

module Pwnlib
  # A simple timer class.
  # TODO(Darkpi): Python pwntools seems to have many unreasonable codes in this class,
  #               not sure of the use case of this, check if everything is coded as
  #               intended after we have some use cases. (e.g. sock)
  class Timer
    # DIFF: We just use nil for default and :forever for forever.

    def initialize(parent, timeout = nil)
      @stop = nil
      @parent = parent
      timeout ||= Pwnlib::Context.context.timeout
      self.timeout = timeout
    end

    def timeout
      return @timeout unless @stop
      [@stop - Time.now, 0].max
    end

    def timeout=(timeout)
      @timeout = Context.timeout_sec(timeout)
      @parent.timeout_changed(self)
    end

    def active?
      # XXX(Darkpi): Why should @stop == nil count as active??? (as in Python pwntool)
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
