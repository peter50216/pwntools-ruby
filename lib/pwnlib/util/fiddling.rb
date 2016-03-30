# encoding: ASCII-8BIT
require 'pwnlib/context'

module Pwnlib
  module Util
    # Some fiddling methods
    module Fiddling
      include Pwnlib::Context

      module_function

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
            r = s.to_s(2).chars.map { |ch| ch == '1' ? one : zero }
            r.unshift(zero) until r.size % 8 == 0
            is_little ? r.reverse : r
          else
            raise ArgumentError, 's must be either String or Integer'
          end
        end
      end
    end
  end
end
