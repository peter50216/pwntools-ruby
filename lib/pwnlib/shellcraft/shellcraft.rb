# encoding: ASCII-8BIT
require 'singleton'

require 'pwnlib/constants/constant'
require 'pwnlib/context'
require 'pwnlib/shellcraft/registers'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/packing'

module Pwnlib
  # Implement shellcraft!
  module Shellcraft
    # Return the shellcraft instance for further usage.
    def self.instance
      Root.instance
    end

    # For templates/*.rb to define shellcode generators.
    def self.define(filename, *args, &block)
      path = filename.sub(Submodule::ROOT_DIR + '/', '').rpartition('.').first # remove '.rb'
      AsmMethods.define(path, *args, &block)
    end

    # To support like +Shellcraft.amd64.linux.syscall+.
    #
    # A {Shellcraft::Submodule} object will be returned when calling +Shellcraft.amd64+, so we can continue to call
    # +.linux.syscall+, which actually is 'directories traversal' handled in {Submodule}.
    class Submodule
      ROOT_DIR = File.join(__dir__, 'templates').freeze

      # @param [String] name
      #   The relative path of this module.
      #
      # @example
      #   Submodule.new('amd64/linux')
      def initialize(name)
        @name = name
        @modules = {}
      end

      # For dynamic define methods.
      def method_missing(method, *args, &_)
        # +add_module+ success if +method+ is a directory
        return public_send(method, *args) if add_module(method) || add_method(method)
        # neither a dir nor a file
        super
      end

      def respond_to_missing?(method, _include_private)
        return true if add_module(method) || add_method(method)
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
        File.file?(path("#{method}.rb"))
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
        filepath = glob(method)
        return false unless filepath

        # find file path in +context.arch+, and call it.
        define_singleton_method(method) do |*args|
          filepath = glob(method) # find again because context.arch might be changed.
          # If method already been defined but architecture changed,
          # needs to raise method_missing.
          return method_missing(method, *args) unless filepath
          list = filepath.split('/')
          list = list[(list.rindex(@name) + 1)..-2]
          list.reduce(self) { |acc, elem| acc.public_send(elem) }.public_send(method, *args)
        end
        true
      end

      def glob(method)
        Dir.glob(File.join(ROOT_DIR, @name, context.arch, '**', "#{method}.rb")).first
      end

      include ::Pwnlib::Context
    end

    # Records every methods that have been invoked, lazy binding.
    #
    # This module is for internal use only.
    module AsmMethods
      @methods = {}

      # @param [String] path
      #   The relative path that contains +method+.rb.
      # @param [Symbol] method
      #   Assembly method to be called.
      # @param [Array] args
      #   Arguments to be passed.
      #
      # @return [String]
      #   The assembly codes.
      #
      # @example
      #   AsmMethods.call('./amd64/linux', :syscall, ['SYS_read', 0, 'rsp', 10])
      #   => <assembly codes>
      def self.call(path, method, *args)
        require File.join(Submodule::ROOT_DIR, path, method.to_s) # require 'templates/amd64/linux/syscall'
        list = [*path.split('/')[1..-1].map(&:to_sym), method]
        runner = list.reduce(@methods) do |cur, key|
          raise ArgumentError, "Method `#{method}` has not been defined by #{path}/#{method}.rb!" unless cur.key?(key)
          cur[key]
        end
        runner.call(*args)
      end

      # @param [String] name
      #   The name to be defined, see examples.
      #
      # @example
      #   AsmMethods.define('amd64/nop') { cat 'nop' }
      #   # Now can invoke AsmMethods.call('amd64', :nop).
      def self.define(name, &block)
        list = name.split('/').map(&:to_sym)
        method = list.pop
        obj = list.reduce(@methods) do |cur, key|
          cur[key] ||= {}
        end
        obj[method] = Runner.new.tap do |runner|
          runner.define_singleton_method(:inner, &block)
        end
      end

      # A 'sandbox' class to run assembly generators (i.e. shellcraft/templates/*.rb).
      #
      # @note This class should never be used externally, only {AsmMethods} can use it.
      class Runner
        def call(*args)
          @_output = StringIO.new
          inner(*args)
          typesetting
        end

        private

        # Indent each line 2 space.
        # TODO(david942j): consider labels
        def typesetting
          @_output.string.lines.map { |line| line == "\n" ? line : ' ' * 2 + line.lstrip }.join
        end

        # For templates/*.rb use.

        def cat(str)
          @_output.puts str
        end

        def okay(s, *a, **kw)
          s = Util::Packing.pack(s, *a, **kw) if s.is_a?(Integer)
          !(s.include?("\x00") || s.include?("\n"))
        end

        def evaluate(item)
          return item if ::Pwnlib::Shellcraft::Registers.register?(item)
          Constants.eval(item)
        end

        # @param [Constants::Constant, String, Integer] n
        def pretty(n)
          case n
          when Constants::Constant
            format('%s /* %s */', pretty(n.to_i), n)
          when Integer
            n.abs < 10 ? n.to_s : Util::Fiddling.hex(n)
          else
            n.inspect
          end
        end

        def shellcraft
          ::Pwnlib::Shellcraft.instance
        end

        include ::Pwnlib::Context
      end
    end
  end
end
