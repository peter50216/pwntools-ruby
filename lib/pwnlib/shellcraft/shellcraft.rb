# encoding: ASCII-8BIT
require 'pwnlib/context'
require 'pwnlib/util/packing'
require 'pwnlib/util/fiddling'
require 'pwnlib/constants/constant'
require 'singleton'

module Pwnlib
  # Implement shellcraft!
  module Shellcraft
    # Return the shellcraft instance for furthur usage.
    def self.instance
      Root.instance
    end

    # For templates/*.rb to define shellcode generators.
    def self.define(name, *args, &block)
      AsmMethods.define(name, *args, &block)
    end

    # To support like +Shellcraft.amd64.linux.syscall+.
    #
    # return a {Shellcraft::Submodule} object when call +Shellcraft.amd64+, and do the
    # 'directories traversal' for furthur calling.
    class Submodule
      ROOT_DIR = File.join(__dir__, 'templates')

      # @param [String] name
      #   The relative path of this module.
      # @example
      #   Submodule.new('amd64/linux')
      def initialize(name)
        @name = name
        @modules = {}
      end

      # For dynamic define methods.
      def method_missing(method, *args, &_)
        return @modules[method] if add_module(method)

        # not a dir, define method.
        return super unless add_method(method) # +return super+ when file not found
        # method must be defined now.
        public_send(method, *args)
      end

      def respond_to_missing?(method, _include_private)
        return true if add_module(method)
        return true if add_method(method)
        false
      end

      private

      def add_method(method)
        return false unless rbfile?(method)
        define_singleton_method(method) do |*args|
          AsmMethods.call(@name, method, *args)
        end
        true
      end

      # @param [Symbol] method
      def add_module(method)
        return false unless dir?(method) # not a dir
        @modules[method] = Submodule.new(File.join(@name, method.to_s))
        # add submodule method!
        define_singleton_method(method) { @modules[method] }
        true
      end

      def dir?(method)
        File.directory?(path(method))
      end

      def rbfile?(method)
        File.exist?(path("#{method}.rb"))
      end

      def path(method)
        File.join(ROOT_DIR, @name, method.to_s)
      end
    end

    # The root module
    class Root < Submodule
      include ::Singleton
      def initialize
        super('.') # root dir
      end

      private

      def add_method(method)
        # If method not presents in current arch, ignore it.
        filepath = glob(method.to_s)
        return false unless filepath

        # find file path in +context.arch+, and call it.
        define_singleton_method(method) do |*args|
          filepath = glob(method.to_s) # find again because context.arch might be changed.
          # If method already been defined but architecture changed,
          # needs to raise method_missing.
          return method_missing(method, *args) unless filepath
          # here sucks...
          list = filepath[filepath.rindex("/#{@name}/")..-1].split('/').slice(2..-2).map(&:to_sym)
          list.reduce(self) { |acc, elem| acc.public_send(elem) }.public_send(method, *args)
        end
        true
      end

      def glob(name)
        Dir.glob(File.join(ROOT_DIR, @name, context.arch, '**', "#{name}.rb")).first
      end

      include ::Pwnlib::Context
    end

    # Records every methods that invoked, lazy binding.
    module AsmMethods
      @methods = {}

      # @param [String] path
      #   The relative path that contains `method`.rb.
      # @param [Symbol] method
      #   Assembly method to be called.
      # @param [Array] args
      #   Arguments to be passed.
      #
      # @return [String]
      #   The assembly codes.
      #
      # @example
      #   AsmMethods.call('amd64/linux', :syscall, ['SYS_read', 0, 'rsp', 10])
      #   => <assembly codes>
      def self.call(path, method, *args)
        require File.join(Submodule::ROOT_DIR, path, method.to_s) # require 'templates/amd64/linux/syscall'
        list = [*path.split('/').reject { |s| s.include?('.') }.map(&:to_sym), method]
        runner = list.reduce(@methods) do |cur, key|
          raise ArgumentError, "Method `#{method}` not been defined by #{path}/#{method}.rb!" unless cur.key?(key)
          cur[key]
        end
        runner.call(*args)
      end

      # @param [String] name
      #   The name includes module path to be defined.
      # @example
      #   AsmMethods.define('amd64.nop') { cat 'nop' }
      #   # Now can invoke AsmMethods.call('amd64', :nop).
      def self.define(name, &block)
        list = name.split('.').map(&:to_sym)
        obj = list[0...-1].reduce(@methods) do |cur, key|
          cur[key] = {} unless cur.key?(key)
          cur[key]
        end
        obj[list.last] = Runner.new
        meta = class << obj[list.last]
          self
        end
        meta.instance_eval do
          define_method(:inner, &block)
        end
      end

      # A 'sandbox' class to run assembly generators (i.e. shellcraft/templates/*.rb).
      # @note This class should never be used externally, only {AsmMethods} can use it.
      class Runner
        def call(*args)
          @_output = ''
          inner(*args)
          typesetting
        end

        private

        # Indent each line 2 space.
        # TODO(david942j): consider labels
        def typesetting
          @_output.lines.map { |line| ' ' * 2 + line.lstrip }.join
        end

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

        # @param [Constants::Constant, String, Integer] n
        def pretty(n, comment: true)
          case n
          when Constants::Constant
            format(comment ? '%s /* %s */' : '%s (%s)', n, pretty(n.to_i))
          when Integer
            n.abs < 10 ? n.to_s : Util::Fiddling.hex(n)
          else
            n.inspect
          end
        end

        include ::Pwnlib
      end
    end
  end
end
