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
      # TODO(david942j): support Shellcraft.amd64.linux.syscall
      AsmRender.run(method, *args) || super
    end

    # Class for running .rb to acquire the result assembly.
    class AsmRender
      def initialize(method, *args)
        @method = method
        @args = args
      end

      def work
        @_output = ''
        filename = self.class.file_of(@method)
        # method {@method} must be defined after instance_eval.
        instance_eval(File.read(filename))
        send(@method, *@args)
        typesetting
      end

      private

      # Indent each line 2 space.
      # TODO(david942j): consider labels
      def typesetting
        @_output.lines.map do |line|
          ' ' * 2 + line.lstrip
        end.join
      end

      # For templates/*.rb use

      def cat(str)
        @_output.concat str + (str.end_with?("\n") ? '' : "\n")
      end

      def okay(s, *a, **kw)
        s = ::Pwnlib::Util::Packing.pack(s, *a, **kw) if s.is_a?(Integer)
        !(s.include?("\x00") || s.include?("\n"))
      end

      def eval(item)
        return item if item.is_a?(Integer)
        ::Pwnlib::Constants.eval(item)
      end
      alias evaluate eval

      def pretty(n, comment: true)
        return n.inspect if n.is_a?(String)
        return n unless n.is_a?(Numeric)
        if n.instance_of?(::Pwnlib::Constants::Constant)
          return format(comment ? '%s /* %s */' : '%s (%s)', n, pretty(n.to_i))
        end
        return n if n.abs < 10
        ::Pwnlib::Util::Fiddling.hex(n)
      end
      # Static methods.
      class << self
        # Check if can find {name}.rb in current context.
        # @return [Boolean] if {name}.rb exists.
        def exists?(name)
          file_of(name) != nil
        end

        def file_of(name)
          Dir.glob(File.join(__dir__, 'templates', context.arch, '**', "#{name}.rb")).first
        end

        def run(name, *args)
          return nil unless exists?(name)
          AsmRender.new(name, *args).work
        end
        include ::Pwnlib::Context
      end
    end
  end
end
