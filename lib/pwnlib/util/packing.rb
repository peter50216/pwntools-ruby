# encoding: ASCII-8BIT

require 'pwnlib/context'

module Pwnlib
  module Util
    # Methods for integer pack/unpack.
    #
    # @example Call by specifying full module path.
    #   require 'pwnlib/util/packing'
    #   Pwnlib::Util::Packing.p8(217) #=> "\xD9"
    # @example require 'pwn' and have all methods.
    #   require 'pwn'
    #   p8(217) #=> "\xD9"
    module Packing
      module_function

      # Pack arbitrary-sized integer.
      #
      # +bits+ indicates number of bits that packed output should use.
      # The output would be padded to be byte-aligned.
      #
      # +bits+ can also be the string 'all', indicating that the result should be long enough to hold all bits of the
      # number.
      #
      # @param [Integer] number
      #   Number to be packed.
      # @param [Integer, 'all'] bits
      #   Number of bits the output should have, or +'all'+ for all bits.
      #   Default to +context.bits+.
      # @param [String] endian
      #   Endian to use when packing.
      #   Can be any value accepted by context (See {Context::ContextType}).
      #   Default to +context.endian+.
      # @param [Boolean, String] signed
      #   Whether the input number should be considered signed when +bits+ is +'all'+.
      #   Can be any value accepted by context (See {Context::ContextType}).
      #   Default to +context.signed+.
      #
      # @return [String]
      #   The packed string.
      #
      # @raise [ArgumentError]
      #   When input integer can't be packed into the size specified by +bits+ and +signed+.
      #
      # @example
      #   pack(0x34, bits: 8) #=> '4'
      #   pack(0x1234, bits: 16, endian: 'little') #=> "4\x12"
      #   pack(0xFF, bits: 'all', signed: false) #=> "\xFF"
      #   pack(0xFF, bits: 'all', endian: 'big', signed: true) #=> "\x00\xFF"
      def pack(number, bits: nil, endian: nil, signed: nil)
        if bits == 'all'
          bits = nil
          is_all = true
        else
          is_all = false
        end

        context.local(bits: bits, endian: endian, signed: signed) do
          bits = context.bits
          endian = context.endian
          signed = context.signed

          # Verify that bits make sense
          if signed
            bits = (number.bit_length | 7) + 1 if is_all

            limit = 1 << (bits - 1)
            unless -limit <= number && number < limit
              raise ArgumentError, "signed number=#{number} does not fit within bits=#{bits}"
            end
          else
            if is_all
              raise ArgumentError, "Can't pack negative number with bits='all' and signed=false" if number < 0
              bits = number.zero? ? 8 : ((number.bit_length - 1) | 7) + 1
            end

            limit = 1 << bits
            unless 0 <= number && number < limit
              raise ArgumentError, "unsigned number=#{number} does not fit within bits=#{bits}"
            end
          end

          number &= (1 << bits) - 1
          bytes = (bits + 7) / 8

          out = []
          bytes.times do
            out << (number & 0xFF)
            number >>= 8
          end
          out = out.pack('C*')

          endian == 'little' ? out : out.reverse
        end
      end

      # Unpack packed string back to integer.
      #
      # +bits+ indicates number of bits that should be used from input data.
      #
      # +bits+ can also be the string +'all'+, indicating that all bytes from input should be used.
      #
      # @param [String] data
      #   String to be unpacked.
      # @param [Integer, 'all'] bits
      #   Number of bits to be used from +data+, or +'all'+ for all bits.
      #   Default to +context.bits+
      # @param [String] endian
      #   Endian to use when unpacking.
      #   Can be any value accepted by context (See {Context::ContextType}).
      #   Default to +context.endian+.
      # @param [Boolean, String] signed
      #   Whether the output number should be signed.
      #   Can be any value accepted by context (See {Context::ContextType}).
      #   Default to +context.signed+.
      #
      # @return [Integer]
      #   The unpacked number.
      #
      # @raise [ArgumentError]
      #   When +data.size+ doesn't match +bits+.
      #
      # @example
      #   unpack('4', bits: 8) #=> 52
      #   unpack("\x3F", bits: 6, signed: false) #=> 63
      #   unpack("\x3F", bits: 6, signed: true) #=> -1
      def unpack(data, bits: nil, endian: nil, signed: nil)
        bits = data.size * 8 if bits == 'all'

        context.local(bits: bits, endian: endian, signed: signed) do
          bits = context.bits
          endian = context.endian
          signed = context.signed
          bytes = (bits + 7) / 8

          raise ArgumentError, "data.size=#{data.size} does not match with bits=#{bits}" unless data.size == bytes

          data = data.reverse if endian == 'little'
          data = data.unpack('C*')
          number = 0
          data.each { |c| number = (number << 8) + c }
          number &= (1 << bits) - 1
          if signed
            signbit = number & (1 << (bits - 1))
            number -= 2 * signbit
          end
          number
        end
      end

      # Split the data into chunks, and unpack each element.
      #
      # +bits+ indicates how many bits each chunk should be.
      # This should be a multiple of 8, and size of +data+ should be divisible by +bits / 8+.
      #
      # +bits+ can also be the string +'all'+, indicating that all bytes from input would be used, and result would be
      # an array with one element.
      #
      # @param [String] data
      #   String to be unpacked.
      # @param [Integer, 'all'] bits
      #   Number of bits to be used for each chunk of +data+,
      #   or +'all'+ for all bits.
      #   Default to +context.bits+
      # @param [String] endian
      #   Endian to use when unpacking.
      #   Can be any value accepted by context (See {Context::ContextType}).
      #   Default to +context.endian+.
      # @param [Boolean, String] signed
      #   Whether the output number should be signed.
      #   Can be any value accepted by context (See {Context::ContextType}).
      #   Default to +context.signed+.
      #
      # @return [Array<Integer>]
      #   The unpacked numbers.
      #
      # @raise [ArgumentError]
      #   When +bits+ isn't divisible by 8 or +data.size+ isn't divisible by +bits / 8+.
      #
      # @todo
      #   Support +bits+ not divisible by 8, if ever found this useful.
      #
      # @example
      #   unpack_many('haha', bits: 8) #=> [104, 97, 104, 97]
      #   unpack_many("\xFF\x01\x02\xFE", bits: 16, endian: 'little', signed: true) #=> [511, -510]
      #   unpack_many("\xFF\x01\x02\xFE", bits: 16, endian: 'big', signed: false) #=> [65281, 766]
      def unpack_many(data, bits: nil, endian: nil, signed: nil)
        return [unpack(data, bits: bits, endian: endian, signed: signed)] if bits == 'all'

        context.local(bits: bits, endian: endian, signed: signed) do
          bits = context.bits

          # TODO(Darkpi): Support this if found useful.
          raise ArgumentError, 'bits must be a multiple of 8' if bits % 8 != 0

          bytes = bits / 8

          raise ArgumentError, "data.size=#{data.size} must be a multiple of bytes=#{bytes}" if data.size % bytes != 0
          ret = []
          (data.size / bytes).times do |idx|
            x1 = idx * bytes
            x2 = x1 + bytes
            # We already set local context, no need to pass things down.
            ret << unpack(data[x1...x2], bits: bits)
          end
          ret
        end
      end

      { 8 => 'c', 16 => 's', 32 => 'l', 64 => 'q' }.each do |sz, ch|
        define_method("p#{sz}") do |num, **kwargs|
          context.local(**kwargs) do
            c = context.signed ? ch : ch.upcase
            arrow = context.endian == 'little' ? '<' : '>'
            arrow = '' if sz == 8
            [num].pack("#{c}#{arrow}")
          end
        end

        define_method("u#{sz}") do |data, **kwargs|
          context.local(**kwargs) do
            c = context.signed ? ch : ch.upcase
            arrow = context.endian == 'little' ? '<' : '>'
            arrow = '' if sz == 8
            data.unpack("#{c}#{arrow}")[0]
          end
        end
      end

      # TODO(Darkpi):
      #   pwntools-python have this for performance reason, but current implementation doesn't offer that much
      #   performance relative to what pwntools-python do. Maybe we should initialize those functions (p8lu, ...)
      #   like in pwntools-python?
      [%w(pack p), %w(unpack u)].each do |v1, v2|
        define_method("make_#{v1}er") do |bits: nil, endian: nil, signed: nil|
          context.local(bits: bits, endian: endian, signed: signed) do
            bits = context.bits
            endian = context.endian
            signed = context.signed

            if [8, 16, 32, 64].include?(bits)
              ->(num) { ::Pwnlib::Util::Packing.public_send("#{v2}#{bits}", num, endian: endian, signed: signed) }
            else
              ->(num) { ::Pwnlib::Util::Packing.public_send(v1, num, bits: bits, endian: endian, signed: signed) }
            end
          end
        end
      end

      def flat(*args, **kwargs, &preprocessor)
        ret = []
        p = make_packer(**kwargs)
        args.each do |it|
          if preprocessor && !it.is_a?(Array)
            r = preprocessor[it]
            it = r unless r.nil?
          end
          v = case it
              when Array then flat(*it, **kwargs, &preprocessor)
              when Integer then p[it]
              when String then it.force_encoding('ASCII-8BIT')
              else
                raise ArgumentError, "flat does not support values of type #{it.class}"
              end
          ret << v
        end
        ret.join
      end

      # TODO(Darkpi): fit! Which seems super useful.

      include ::Pwnlib::Context
    end
  end
end
