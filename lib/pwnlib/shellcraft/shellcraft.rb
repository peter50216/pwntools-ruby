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
      AsmRenderer.run(method, args) || Submodule.get(method) || super
    end

    # To support like Shellcraft.amd64.linux.syscall.
    #
    # return a Submodule object when call Shellcraft.amd64, and do the
    # `directories traversal' for furthur calling.
    class Submodule
      def initialize(name)
        @name = name
      end

      def method_missing(method, *args, &_)
        super unless exists?(method)
        return Submodule.get(File.join(@name, method.to_s)) if dir?(method)
        AsmRenderer.run(method, args, path: @name) || super
      end

      private

      def dir?(method)
        File.directory?(path(method))
      end

      def exists?(method)
        File.exist?(path(method)) || File.exist?(path("#{method}.rb"))
      end

      def path(method)
        File.join(AsmRenderer::TEMPLATES, @name, method.to_s)
      end

      def self.get(name)
        name = name.to_s
        return nil unless File.exist?(File.join(AsmRenderer::TEMPLATES, name))
        Submodule.new(name)
      end
    end

    # For render templates.
    module AsmRenderer
      TEMPLATES = File.join(__dir__, 'templates')
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
        #   AsmRenderer.run(:mov, ['rax', 'rbx'], path: './amd64/')
        #   => " mov rax, rbx\n"
        def run(method, args, path: nil)
          path ||= "./#{context.arch}/**/"
          return nil unless exists?(path, method)
          typesetting(Render.new(method, file_of(path, method), args).work)
        end

        # Indent each line 2 space.
        # TODO(david942j): consider labels
        def typesetting(result)
          result.lines.map do |line|
            ' ' * 2 + line.lstrip
          end.join
        end

        include ::Pwnlib::Context
      end

      # Class for providing a `sandbox' to run *.rb and acquire the result assembly.
      class Render
        # Then we don't need Pwnlib:: in templates.
        include ::Pwnlib
        def initialize(method, filename, args)
          @method = method
          @filename = filename
          @args = args
        end

        # Pass to module Shellcraft when method missing.
        def method_missing(method, *args, &block)
          Shellcraft.send(method, *args, &block)
        end

        def work
          @_output = ''
          instance_eval(File.read(@filename))
          # method {@method} must be defined after instance_eval.
          send(@method, *@args)
          @_output
        end

        private

        # For templates/*.rb use.

        def cat(str)
          @_output.concat str + (str.end_with?("\n") ? '' : "\n")
        end

        def okay(s, *a, **kw)
          s = Util::Packing.pack(s, *a, **kw) if s.is_a?(Integer)
          !(s.include?("\x00") || s.include?("\n"))
        end

        def eval(item)
          return item if item.is_a?(Integer)
          Constants.eval(item)
        end
        alias evaluate eval

        def pretty(n, comment: true)
          return n.inspect if n.is_a?(String)
          return n unless n.is_a?(Numeric)
          if n.instance_of?(Constants::Constant)
            return format(comment ? '%s /* %s */' : '%s (%s)', n, pretty(n.to_i))
          end
          return n if n.abs < 10
          Util::Fiddling.hex(n)
        end
      end
    end
  end
end
