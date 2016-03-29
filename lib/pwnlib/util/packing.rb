require 'pwnlib/context'

module Pwnlib
  module Util
    # Methods for integer pack/unpack
    module Packing
      module_function

      def pack(number, bits: nil, endian: nil, signed: nil)
        unless number.is_a?(Integer)
          raise ArgumentError, 'number must be an integer'
        end

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
              if number < 0
                raise ArgumentError, "Can't pack negative number with bits='all' and signed=false"
              end
              bits = number == 0 ? 8 : ((number.bit_length - 1) | 7) + 1
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

      def unpack(data, bits: nil, endian: nil, signed: nil)
        bits = data.size * 8 if bits == 'all'

        context.local(bits: bits, endian: endian, signed: signed) do
          bits = context.bits
          endian = context.endian
          signed = context.signed
          bytes = (bits + 7) / 8

          unless data.size == bytes
            raise ArgumentError, "data.size=#{data.size} does not match with bits=#{bits}"
          end

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

      def unpack_many(data, bits: nil, endian: nil, signed: nil)
        return [unpack(data, bits: bits, endian: endian, signed: signed)] if bits == 'all'

        context.local(bits: bits, endian: endian, signed: signed) do
          bits = context.bits

          # TODO(Darkpi): Support this if found useful.
          raise ArgumentError, 'bits must be a multiple of 8' if bits % 8 != 0

          bytes = bits / 8

          if data.size % bytes != 0
            raise ArgumentError, "data.size=#{data.size} must be a multiple of bytes=#{bytes}"
          end
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

      # TODO(Darkpi): pwntools-python have this for performance reason,
      #               but current implementation doesn't offer that much performance
      #               relative to what pwntools-python do. Maybe we should initialize
      #               those functions (p8lu, ...) like in pwntools-python?
      def make_packer(bits: nil, endian: nil, signed: nil)
        context.local(bits: bits, endian: endian, signed: signed) do
          bits = context.bits
          endian = context.endian
          signed = context.signed

          if [8, 16, 32, 64].include?(bits)
            ->(num) { send("p#{bits}", num, endian: endian, signed: signed) }
          else
            ->(num) { pack(num, bits: bits, endian: endian, signed: signed) }
          end
        end
      end

      def make_unpacker(bits: nil, endian: nil, signed: nil)
        context.local(bits: bits, endian: endian, signed: signed) do
          bits = context.bits
          endian = context.endian
          signed = context.signed

          if [8, 16, 32, 64].include?(bits)
            ->(data) { send("u#{bits}", data, endian: endian, signed: signed) }
          else
            ->(data) { unpack(data, bits: bits, endian: endian, signed: signed) }
          end
        end
      end

      include Pwnlib::Context
    end
  end
end
