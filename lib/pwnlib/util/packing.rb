require 'pwnlib/context'

module Pwnlib
  module Util
    module Packing
      module_function
      def pack(number, bits = nil, endian = nil, signed = nil, **kwargs)
        raise ArgumentError, 'number must be an integer' unless number.is_a?(Integer)

        if number < 0 && signed.nil?
          signed = true
        end

        kwargs.merge!({
          bits: (bits == 'all' ? nil : bits),
          endian: endian,
          signed: signed
        }) do |_, v1, v2|
          v1.nil? ? v2 : v1
        end
        kwargs.delete_if{|k, v| v.nil?}

        context.local(**kwargs) do
          bits = (bits == 'all' ? 'all' : context.bits)
          endian = context.endian
          signed = context.signed

          # Verify that bits make sense
          if bits == 'all'
            if signed
              bits = (number.bit_length | 7) + 1
            else
              if number < 0
                raise ArgumentError,
                  "Can't pack negative number with bits='all' and signed=false"
              end
              bits = number == 0 ? 8 : ((number.bit_length - 1) | 7) + 1
            end
          end

          if signed
            limit = 1 << (bits - 1)
            unless -limit <= number && number < limit
              raise ArgumentError, "signed number=#{number} does not fit within bits=#{bits}"
            end
          else
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

      def unpack(data, bits = nil, endian = nil, signed = nil, **kwargs)
        kwargs.merge!({
          bits: (bits == 'all' ? data.size * 8 : bits),
          endian: endian,
          signed: signed
        }) do |_, v1, v2|
          v1.nil? ? v2 : v1
        end
        kwargs.delete_if{|k, v| v.nil?}

        context.local(**kwargs) do
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
          data.each{|c| number = (number << 8) + c}
          number &= (1 << bits) - 1
          if signed
            signbit = number & (1 << (bits - 1))
            number -= 2 * signbit
          end
          number
        end
      end

      extend Pwnlib::Context
      private_class_method :context
    end
  end
end
