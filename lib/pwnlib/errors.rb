# encoding: ASCII-8BIT

module Pwnlib
  # Generic {Pwnlib} exception class.
  class Error < StandardError
  end

  # Pnwlib Errors
  module Errors
    # Raised by some IO operations.
    class EOFError < ::Pwnlib::Error
    end

    # Raised when a file required (dependencies, etc.) fails to load.
    class LoadError < ::Pwnlib::Error
    end

    # Raised when a given name is invalid or undefined.
    class NameError < ::Pwnlib::Error
    end

    # Raised when timeout exceeded.
    class TimeoutError < ::Pwnlib::Error
    end
  end
end
