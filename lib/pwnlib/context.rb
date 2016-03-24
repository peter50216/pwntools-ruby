require 'logger'

# TODO(Darkpi): Check if there should be special care for threading.

module Pwnlib
  module Context
    class ContextType
      DEFAULT = {
        arch: 'i386',
        bits: 32,
        endian: 'little',
        log_level: Logger::INFO,
        newline: "\n",
        os: 'linux',
        signed: false,
        timeout: Float::INFINITY,
      }

      OSES = %w(linux freebsd windows).sort

      BIG_32    = {endian: 'big', bits: 32}
      BIG_64    = {endian: 'big', bits: 64}
      LITTLE_8  = {endian: 'little', bits: 8}
      LITTLE_16 = {endian: 'little', bits: 16}
      LITTLE_32 = {endian: 'little', bits: 32}
      LITTLE_64 = {endian: 'little', bits: 64}

      class << self
        private
        def longest(d)
          Hash[d.sort_by{|k, v| k.length}.reverse]
        end
      end

      ARCHS = longest({
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
        'vax' => LITTLE_32,
      })

      ENDIANNESSES = longest({
        'be' => 'big',
        'eb' => 'big',
        'big' => 'big',
        'le' => 'little',
        'el' => 'little',
        'little' => 'little',
      })

      SIGNEDNESSES = {
        'unsigned' => false,
        'no' => false,
        'yes' => true,
        'signed' => true,
      }

      VALID_SIGNED = SIGNEDNESSES.keys

      def initialize(**kwargs)
        @attrs = DEFAULT.dup
        update(**kwargs)
      end

      def update(**kwargs)
        kwargs.each do |k, v|
          self.public_send("#{k}=", v)
        end
        self
      end

      alias [] update
      alias call update

      def to_s
        vals = @attrs.map{|k, v| "#{k} = #{v.inspect}"}
        "#{self.class}(#{vals.join(', ')})"
      end

      def local(**kwargs)
        raise ArgumentError, "Need a block for #{self.class}##{__callee__}" unless block_given?
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

      DEFAULT.keys.each do |k|
        define_method(k) { @attrs[k] }
      end

      def newline=(newline)
        @attrs[:newline] = newline
      end

      # TODO(Darkpi): Timeout module.
      def timeout=(timeout)
        @attrs[:timeout] = timeout
      end

      # Difference from Python pwntools:
      # We always change +bits+ and +endian+ field whether user have already changed them.
      def arch=(arch)
        arch = arch.downcase.gsub(/[[:punct:]]/, '')
        defaults = ARCHS[arch]
        raise ArgumentError, "arch must be one of #{ARCHS.keys.sort.inspect}" unless defaults
        defaults.each { |k, v| @attrs[k] = v }
        @attrs[:arch] = arch
      end

      # TODO(Darkpi): #binary when we can read ELF.
    end

    @context = ContextType.new
    class << self
      attr_reader :context
    end
  end
end
