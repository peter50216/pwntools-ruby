#encoding: ASCII-8BIT

require 'pwnlib/context'
module Pwnlib
  module Constants
    module ClassMethod
      include ::Pwnlib::Context
      ENV_STORE = {}
      def method_missing(method, *_)
        get_constant(method.to_s) || super
      end

      def eval(str)
        return str unless str.instance_of? String
        # TODO(david942j): safeeval
        send(str.symbol)
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
        return nil unless File.exists? filename
        require filename # require will not do twice, so no need to check if key exists
        ENV_STORE[cur_arch_key][name.to_sym] || ENV_STORE[cur_arch_key][name.to_s]
      end
    end

    extend ClassMethod
  end
end
