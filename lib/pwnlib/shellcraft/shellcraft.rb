# encoding: ASCII-8BIT
require 'pwnlib/context'
require 'pwnlib/util/packing'
require 'pwnlib/util/fiddling'
require 'pwnlib/constants/constant'

module Pwnlib
  # Implement shellcraft!
  module Shellcraft
    def self.method_missing(method, *args, &_)
      # no asm need block?
      AsmRender.run(method, args) || Submodule.get(method) || super
    end

    # To support like Shellcraft.amd64.linux.syscall.
    #
    # return a Submodule object when call Shellcraft.amd64, and do the `directory traversal'.
    class Submodule
      def initialize(name)
        @name = name
      end

      def method_missing(method, *args, &_)
        super unless exists?(method)
        return Submodule.get(File.join(@name, method.to_s)) if dir?(method)
        AsmRender.run(method, args, path: @name) || super
      end

      private

      def dir?(method)
        File.directory?(path(method))
      end

      def exists?(method)
        File.exist?(path(method)) || File.exist?(path("#{method}.rb"))
      end

      def path(method)
        File.join(AsmRender::TEMPLATES, @name, method.to_s)
      end

      def self.get(name)
        name = name.to_s
        return nil unless File.exist?(File.join(AsmRender::TEMPLATES, name))
        Submodule.new(name)
      end
    end

    # Class for running .rb to acquire the result assembly.
    class AsmRender
      TEMPLATES = File.join(__dir__, 'templates')
      def initialize(method, filename, args)
        @method = method
        @filename = filename
        @args = args
      end

      def work
        @_output = ''
        instance_eval(File.read(@filename))
        # method {@method} must be defined after instance_eval.
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
        def exists?(path, name)
          filename = file_of(path, name)
          !filename.nil? && File.file?(filename)
        end

        def file_of(path, name)
          Dir.glob(File.join(TEMPLATES, path, "#{name}.rb")).first
        end

        # @param [Symbol] method
        #   The target shllcraft name.
        # @param [Array] args
        #   The arguments will pass to `method`.
        # @option [String] path
        #   The relative path to find the desired method.
        #   Current directories is 'templates/'.
        #   If `nil` is given, path will be treated as "./#{context.arch}/**/"
        #
        # @example
        #   AsmRender.run(:mov, ['rax', 'rbx'], path: './amd64/')
        #   => " mov rax, rbx\n"
        def run(method, args, path: nil)
          path ||= "./#{context.arch}/**/"
          return nil unless exists?(path, method)
          AsmRender.new(method, file_of(path, method), args).work
        end
        include ::Pwnlib::Context
      end
    end
  end
end
