# encoding: ASCII-8BIT
require 'pwnlib/context'
require 'pwnlib/util/packing'
require 'pwnlib/util/fiddling'
require 'pwnlib/constants/constant'
require 'tilt'

module Pwnlib
  # Implement shellcraft!
  module Shellcraft
    def self.method_missing(method, *args, &_)
      # no asm need block?
      AsmErbParser.parse(method.to_s, *args) || super
    end

    # For *.asm.erb use
    module ClassMethod
      def okay(s, *a, **kw)
        s = ::Pwnlib::Util::Packing.pack(s, *a, **kw) if s.is_a?(Integer)
        !(s.include?("\x00") || s.include?("\n"))
      end

      def eval(item)
        return item if item.is_a?(Integer)
        ::Pwnlib::Constants.eval(item)
      end

      def pretty(n, comment: true)
        return n.inspect if n.is_a?(String)
        return n unless n.is_a?(Numeric)
        if n.instance_of?(::Pwnlib::Constants::Constant)
          return format(comment ? '%s /* %s */' : '%s (%s)', n, pretty(n.to_i))
        end
        return n if n.abs < 10
        ::Pwnlib::Util::Fiddling.hex(n)
      end
    end

    # There're a few custom defined formats in erb, use a class to parse it.
    class AsmErbParser
      ARGUMENT_REGEXP = /^<%#\s+Argument\((.*)\)\s+%>/
      # Check if can find {name}.asm.erb in current context.
      # @return [Boolean] if {name}.asm.erb exists.
      def self.exists?(name)
        file_of(name) != nil
      end

      def self.file_of(name)
        Dir.glob(File.join(__dir__, 'templates', context.arch, '**', format('%s.asm.erb', name))).first
      end

      def self.parse(name, *args)
        return nil unless exists?(name)
        filename = file_of(name)
        Tilt.new(filename, trim: '>', outvar: '@erbout').render(nil, get_locals(filename, *args))
      end

      def self.get_locals(filename, *args)
        arg_line = IO.binread(filename).lines.find do |line|
          line =~ ARGUMENT_REGEXP
        end
        return nil if arg_line.nil?
        arg_to_hash(arg_line.scan(ARGUMENT_REGEXP)[0][0], args)
      end

      # Parse the argument line and combine args to hash
      #
      # @param [String] args_str The argument line specified in *.asm.erb.
      # @param [Array] args The arguments array from callee.
      #
      # @return [Hash] The result locals hash.
      #
      # @example
      #   arg_to_hash('dest, src, stack_allowed: true', ['rax', 'rcx', {stack_allowed: false}]
      #   # => {dest: 'rax', src: 'rcx', stack_allowed: false}
      #   arg_to_hash('*args', [1, 2, 3, 4])
      #   # => {args: [1, 2, 3, 4]}
      #
      # @note Not support '**kwargs' and '&block'
      # @bug Fails when default value includes ',', e.g. 'key: "123,"'
      def self.arg_to_hash(args_str, args)
        # TODO(david942j): raise ArgumentError when args invalid
        args_hash = args.last.is_a?(Hash) ? args.last : {}
        args_str.split(',').each_with_object({}) do |str, hash|
          str.strip!
          next if str.empty?
          if str.start_with?('*') # *args
            hash[str[1..-1].to_sym] = args
            args = []
            next
          end
          if str.include?(':') # keyword argument
            key, val = str.split(':', 2)
            key = key.strip.to_sym
            hash[key] = args_hash.key?(key) ? args_hash[key] : instance_eval(val) # roooooock
            next
          end
          hash[str.to_sym] = args.shift
        end
      end

      # XXX(david942j, peter50216) is this correct usage of context?
      extend ::Pwnlib::Context
    end
  end
end
