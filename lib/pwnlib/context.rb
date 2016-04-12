# encoding: ASCII-8BIT

require 'logger'

# TODO(Darkpi): Check if there should be special care for threading.

module Pwnlib
  # Context module, store some platform-dependent informations.
  module Context
    # XXX(Darkpi): Should we REALLY put this here?
    FOREVER = (2**20).to_f

    def self.timeout_sec(timeout)
      case timeout
      when :forever then FOREVER
      else
        timeout = timeout.to_f
        raise ArgumentError, 'Timeout cannot be negative' if timeout < 0
        [timeout, FOREVER].min
      end
    end

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
        timeout: Context.timeout_sec(:forever)
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

      # XXX(Darkpi):
      #   Should we just hard-coded all levels here, or should we use Logger#const_defined?
      #   (This would include constant SEV_LEVEL, and exclude UNKNOWN)?
      LOG_LEVELS = %w(DEBUG INFO WARN ERROR FATAL UNKNOWN).freeze

      def initialize(**kwargs)
        @attrs = DEFAULT.dup
        update(**kwargs)
      end

      def update(**kwargs)
        kwargs.each do |k, v|
          next if v.nil?
          public_send("#{k}=", v)
        end
        self
      end

      alias [] update
      alias call update

      def to_s
        vals = @attrs.map { |k, v| "#{k} = #{v.inspect}" }
        "#{self.class}(#{vals.join(', ')})"
      end

      # This would return what the block return.
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

      def clear
        @attrs = DEFAULT.dup
      end

      # Getters here.
      DEFAULT.each_key do |k|
        define_method(k) { @attrs[k] }
      end

      def newline=(newline)
        @attrs[:newline] = newline
      end

      def timeout=(timeout)
        @attrs[:timeout] = Context.timeout_sec(timeout)
      end

      # @diff We always change +bits+ and +endian+ field whether user have already changed them.
      def arch=(arch)
        arch = arch.downcase.gsub(/[[:punct:]]/, '')
        defaults = ARCHS[arch]
        raise ArgumentError, "arch must be one of #{ARCHS.keys.sort.inspect}" unless defaults
        defaults.each { |k, v| @attrs[k] = v }
        @attrs[:arch] = arch
      end

      def bits=(bits)
        raise ArgumentError, "bits must be > 0 (#{bits} given)" unless bits > 0
        @attrs[:bits] = bits
      end

      def bytes
        bits / 8
      end

      def bytes=(bytes)
        self.bits = bytes * 8
      end

      def endian=(endian)
        endian = ENDIANNESSES[endian.downcase]
        raise ArgumentError, "endian must be one of #{ENDIANNESSES.sort.inspect}" if endian.nil?
        @attrs[:endian] = endian
      end

      def log_level=(value)
        log_level = nil
        case value
        when String
          value = value.upcase
          log_level = Logger.const_get(value) if LOG_LEVELS.include?(value)
        when Integer
          log_level = value
        end
        raise ArgumentError, "log_level must be an integer or one of #{LOG_LEVELS.inspect}" unless log_level
        @attrs[:log_level] = log_level
      end

      def os=(os)
        os = os.downcase
        raise ArgumentError, "os must be one of #{OSES.sort.inspect}" unless OSES.include?(os)
        @attrs[:os] = os
      end

      def signed=(value)
        signed = nil
        case value
        when String
          signed = SIGNEDNESSES[value.downcase]
        when true, false
          signed = value
        end
        if signed.nil?
          raise ArgumentError, "signed must be boolean or one of #{SIGNEDNESSES.keys.sort.inspect}"
        end
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
