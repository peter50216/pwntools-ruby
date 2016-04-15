# encoding: ASCII-8BIT
require 'pwnlib/context'

module Pwnlib
  module Util
    # Some fiddling methods
    module Fiddling
      module ClassMethod # rubocop:disable Style/Documentation
        def enhex(s)
          s.unpack('H*')[0]
        end

        def unhex(s)
          [s].pack('H*')
        end

        def urlencode(s)
          s.bytes.map { |b| format('%%%02x', b) }.join
        end

        def urldecode(s, ignore_invalid = false)
          res = ''
          n = 0
          while n < s.size
            if s[n] != '%'
              res << s[n]
              n += 1
            else
              cur = s[n + 1, 2]
              if cur =~ /[0-9a-fA-F]{2}/
                res << cur.to_i(16).chr
                n += 3
              elsif ignore_invalid
                res << '%'
                n += 1
              else
                raise ArgumentError, 'Invalid input to urldecode'
              end
            end
          end
          res
        end

        def bits(s, endian: 'big', zero: 0, one: 1)
          context.local(endian: endian) do
            is_little = context.endian == 'little'
            case s
            when String
              v = 'b*'
              v.upcase! unless is_little
              s.unpack(v)[0].chars.map { |ch| ch == '1' ? one : zero }
            when Integer
              # TODO(Darkpi): What should we do to negative number?
              raise ArgumentError, 's must be non-negative' unless s >= 0
              r = s.to_s(2).chars.map { |ch| ch == '1' ? one : zero }
              r.unshift(zero) until r.size % 8 == 0
              is_little ? r.reverse : r
            else
              raise ArgumentError, 's must be either String or Integer'
            end
          end
        end

        def bits_str(s, endian: 'big', zero: 0, one: 1)
          bits(s, endian: endian, zero: zero, one: one).join
        end

        def unbits(s, endian: 'big')
          s = s.chars if s.is_a?(String)
          context.local(endian: endian) do
            is_little = context.endian == 'little'
            bytes = s.map do |c|
              case c
              when '1', 1, true then '1'
              when '0', 0, false then '0'
              else raise ArgumentError, "cannot decode value #{c.inspect} into a bit"
              end
            end.join
            [bytes].pack(is_little ? 'b*' : 'B*')
          end
        end

        def bitswap(s)
          unbits(bits(s, endian: 'big'), endian: 'little')
        end

        # DIFF: bits default to context.bits
        def bitswap_int(n, bits: nil)
          context.local(bits: bits) do
            bits = context.bits
            n &= (1 << bits) - 1
            bits_str(n, endian: 'little').ljust(bits, '0').to_i(2)
          end
        end

        def b64e(s)
          [s].pack('m0')
        end

        def b64d(s)
          s.unpack('m0')[0]
        end

        private

        include Pwnlib::Context
      end

      extend ClassMethod
    end
  end
end
