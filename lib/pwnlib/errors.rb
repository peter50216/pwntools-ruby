# encoding: ASCII-8BIT

module Pwnlib
  # Generic {Pwnlib} exception class.
  class Error < StandardError
  end

  # Pnwlib Errors
  module Errors
    # Raised by some IO operations in tubes.
    class EndOfTubeError < ::Pwnlib::Error
    end

    # Raised when a dependent file fails to load.
    class DependencyError < ::Pwnlib::Error
    end

    # Raised when a given constant is invalid or undefined.
    class ConstantNotFoundError < ::Pwnlib::Error
    end

    # Raised when timeout exceeded.
    class TimeoutError < ::Pwnlib::Error
    end

    # Raised when method doesn't support under current architecture.
    class UnsupportedArchError < ::Pwnlib::Error
    end
  end
end
