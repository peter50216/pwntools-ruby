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
        s.unpack('H*')[0].scan(/../).map { |i| "%#{i}" }.join
      end

      def urldecode(s, ignore_invalid = false)
        res = ''
        n = 0
        while n < s.length
          if s[n] != '%'
            res += s[n]
            n += 1
          else
            cur = s[n + 1, 2]
            if /[0-9a-fA-F]{2}/.match(cur)
              res += cur.to_i(16).chr
              n += 3
            elsif ignore_invalid
              res += '%'
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
