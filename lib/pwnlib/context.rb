# encoding: ASCII-8BIT

require 'logger'

# TODO(Darkpi): Check if there should be special care for threading.

module Pwnlib
  # Context module, store some platform-dependent informations.
  module Context
    # The type for context. User should never need to initialize one by themself.
    class ContextType
      DEFAULT = {
        arch: 'i386',
        bits: 32,
        endian: 'little',
        log_level: Logger::INFO,
        newline: "\n",
        os: 'linux',
        signed: false,
        timeout: :forever
      }.freeze

      OSES = %w(linux freebsd windows).sort

      BIG_32    = { endian: 'big', bits: 32 }.freeze
      BIG_64    = { endian: 'big', bits: 64 }.freeze
      LITTLE_8  = { endian: 'little', bits: 8 }.freeze
      LITTLE_16 = { endian: 'little', bits: 16 }.freeze
      LITTLE_32 = { endian: 'little', bits: 32 }.freeze
      LITTLE_64 = { endian: 'little', bits: 64 }.freeze

      class << self
        private

        def longest(d)
          Hash[d.sort_by { |k, _v| k.size }.reverse]
        end
      end

      ARCHS = longest(
        'aarch64' => LITTLE_64,
        'alpha' => LITTLE_64,
        'avr' => LITTLE_8,
        'amd64' => LITTLE_64,
        'arm' => LITTLE_32,
        'cris' => LITTLE_32,
        'i386' => LITTLE_32,
        'ia64' => BIG_64,
        'm68k' => BIG_32,
        'mips' => LITTLE_32,
        'mips64' => LITTLE_64,
        'msp430' => LITTLE_16,
        'powerpc' => BIG_32,
        'powerpc64' => BIG_64,
        's390' => BIG_32,
        'sparc' => BIG_32,
        'sparc64' => BIG_64,
        'thumb' => LITTLE_32,
        'vax' => LITTLE_32
      )

      ENDIANNESSES = longest(
        'be' => 'big',
        'eb' => 'big',
        'big' => 'big',
        'le' => 'little',
        'el' => 'little',
        'little' => 'little'
      )

      SIGNEDNESSES = {
        'unsigned' => false,
        'no' => false,
        'yes' => true,
        'signed' => true
      }.freeze

      VALID_SIGNED = SIGNEDNESSES.keys

      # We use Logger#const_defined for pwnlib logger.
      LOG_LEVELS = %w(DEBUG INFO WARN ERROR FATAL UNKNOWN).freeze

      # Instantiate a {Pwnlib::Context::ContextType} object.
      def initialize(**kwargs)
        @attrs = DEFAULT.dup
        update(**kwargs)
      end

      # Convenience function, which is shorthand for setting multiple variables at once.
      #
      # @param [Hash] kwargs
      #   Variables to be assigned in the environment.
      #
      # @example
      #   context.update(arch: 'amd64', os: :linux)
      def update(**kwargs)
        kwargs.each do |k, v|
          next if v.nil?
          public_send("#{k}=", v)
        end
        self
      end

      alias [] update
      alias call update

      # Create a string representation of self.
      def to_s
        vals = @attrs.map { |k, v| "#{k} = #{v.inspect}" }
        "#{self.class}(#{vals.join(', ')})"
      end

      # Create a context manager for a block.
      #
      # @param [Hash] kwargs
      #   Variables to be assigned in the environment.
      #
      # @return
      #   This would return what the block returned.
      #
      # @example
      #   context.local(arch: 'amd64') { puts context.endian }
      #   # little
      def local(**kwargs)
        raise ArgumentError, "Need a block for #{self.class}##{__callee__}" unless block_given?
        # XXX(Darkpi):
        #   improve performance for this if this is too slow, since we use this in many places that has argument
        #   endian / signed / ...
        old_attrs = @attrs.dup
        begin
          update(**kwargs)
          yield
        ensure
          @attrs = old_attrs
        end
      end

      # Clear the contents of the context, which will set all values to their defaults.
      #
      # @example
      #   context.arch = 'amd64'
      #   context.clear
      #   context.bits == 32
      #   #=> true
      def clear
        @attrs = DEFAULT.dup
      end

      # Getters here.
      DEFAULT.each_key do |k|
        define_method(k) { @attrs[k] }
      end

      # Set the newline.
      #
      # @param [String] newline
      #   The newline.
      #
      # @example
      #   context.newline = "\r\n"
      def newline=(newline)
        @attrs[:newline] = newline
      end

      # Set the default amount of time to wait for a blocking operation before it times out.
      #
      # @param [Float, :forever] timeout
      #   Any positive floating number, indicates timeout in seconds.
      #
      # @example
      #   context.timeout = 5.14
      def timeout=(timeout)
        @attrs[:timeout] = timeout
      end

      # Set the architecture of the target binary.
      #
      # @param [String, Symbol] arch
      #   The architecture. Only values in {Pwnlib::Context::ContextType::ARCHS} are available.
      #
      # @diff We always change +bits+ and +endian+ field whether user have already changed them.
      def arch=(arch)
        arch = arch.to_s.downcase.gsub(/[[:punct:]]/, '')
        defaults = ARCHS[arch]
        raise ArgumentError, "arch must be one of #{ARCHS.keys.sort.inspect}" unless defaults
        defaults.each { |k, v| @attrs[k] = v }
        @attrs[:arch] = arch
      end

      # Set the word size of the target machine in bits (i.e. the size of general purpose registers).
      #
      # @param [Integer] bits
      #   The word size.
      def bits=(bits)
        raise ArgumentError, "bits must be > 0 (#{bits} given)" unless bits > 0
        @attrs[:bits] = bits
      end

      # The word size of the target machine.
      def bytes
        bits / 8
      end

      # Set the word size of the target machine in bytes (i.e. the size of general purpose registers).
      #
      # @param [Integer] bytes
      #   The word size.
      def bytes=(bytes)
        self.bits = bytes * 8
      end

      # The endianness of the target machine.
      #
      # @param [String, Symbol] endian
      #   The endianness. Only values in {Pwnlib::Context::ContextType::ENDIANNESSES} are available.
      #
      # @example
      #   context.endian = :big
      def endian=(endian)
        endian = ENDIANNESSES[endian.to_s.downcase]
        raise ArgumentError, "endian must be one of #{ENDIANNESSES.sort.inspect}" if endian.nil?
        @attrs[:endian] = endian
      end

      # Set the verbosity of the logger in +Pwnlib+.
      #
      # @param [String, Symbol] value
      #   The verbosity. Only values in {Pwnlib::Context::ContextType::LOG_LEVELS} are available.
      #
      # @example
      #   context.log_level = :debug
      def log_level=(value)
        log_level = nil
        case value
        when String, Symbol
          value = value.to_s.upcase
          log_level = Logger.const_get(value) if LOG_LEVELS.include?(value)
        when Integer
          log_level = value
        end
        raise ArgumentError, "log_level must be an integer or one of #{LOG_LEVELS.inspect}" unless log_level
        @attrs[:log_level] = log_level
      end

      # Set the operating system of the target machine.
      #
      # @param [String, Symbol] os
      #   The name of the os. Only values in {Pwnlib::Context::ContextType::OSES} are available.
      #
      # @example
      #   context.os = :windows
      def os=(os)
        os = os.to_s.downcase
        raise ArgumentError, "os must be one of #{OSES.sort.inspect}" unless OSES.include?(os)
        @attrs[:os] = os
      end

      # Set the signedness for packing opreation.
      #
      # @param [String, Symbol, true, false] value
      #   The signedness. Only values in {Pwnlib::Context::ContextType::SIGNEDNESSES} are available.
      #
      # @example
      #   context.signed == false
      #   #=> true
      #   context.signed = 'signed'
      #   context.signed == true
      #   #=> true
      def signed=(value)
        signed = nil
        case value
        when String, Symbol
          signed = SIGNEDNESSES[value.to_s.downcase]
        when true, false
          signed = value
        end
        raise ArgumentError, "signed must be boolean or one of #{SIGNEDNESSES.keys.sort.inspect}" if signed.nil?
        @attrs[:signed] = signed
      end

      # TODO(Darkpi): #binary when we can read ELF.
    end

    @context = ContextType.new

    # @!attribute [r] context
    #   @return [ContextType] the singleton context for all class.
    class << self
      attr_reader :context
    end

    # A module for include hook for context.
    # Including Pwnlib::Context from module M would add +context+ as a private instance method and a private class
    # method for module M.
    # @!visibility private
    module IncludeContext
      private

      def context
        ::Pwnlib::Context.context
      end
    end

    # @!visibility private
    def self.included(base)
      base.include(IncludeContext)
      class << base
        include IncludeContext
      end
    end
  end
end
