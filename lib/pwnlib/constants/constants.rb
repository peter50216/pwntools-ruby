# encoding: ASCII-8BIT

require 'pwnlib/context'
require 'pwnlib/constants/constant'

module Pwnlib
  # Module containing constants
  # @example
  #   context.arch = 'amd64'
  #   Pwnlib::Constants.SYS_read
  #   # => Constant('SYS_read', 0x0)
  module Constants
    # @note Do not create and call instance method here. Instead, call module method on {Constants}.
    module ClassMethod
      include ::Pwnlib::Context
      ENV_STORE = {}
      def method_missing(method, *args)
        args.empty? && get_constant(method) || super
      end

      def eval(str)
        return str unless str.instance_of? String
        # TODO(david942j): safeeval
        const = send(str.strip.to_sym)
        ::Pwnlib::Constants::Constant.new(format('(%s)', str), const.val)
      end

      def define
        ENV_STORE[cur_arch_key] = {}
        yield(ENV_STORE[cur_arch_key])
      end

      def cur_arch_key
        [context.os, context.arch]
      end

      def get_constant(name)
        filename = File.join(__dir__, context.os, "#{context.arch}.rb")
        return nil unless File.exist? filename
        require filename # require will not do twice, so no need to check if key exists
        ENV_STORE[cur_arch_key][name.to_sym] || ENV_STORE[cur_arch_key][name.to_s]
      end
    end

    extend ClassMethod
  end
end
