# encoding: ASCII-8BIT

module Pwnlib
  module Util
    # Some fiddling methods
    module Fiddling
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
    end
  end
end
