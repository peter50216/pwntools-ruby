# encoding: ASCII-8BIT

module Pwnlib
  module Util
    # module for some utilities for Ruby metaprogramming.
    module Ruby
      def self.private_class_method_block
        define_singleton_method(:singleton_method_added) do |m|
          private_class_method m
        end
        yield
        class << self
          remove_method(:singleton_method_added)
        end
      end
    end
  end
end
