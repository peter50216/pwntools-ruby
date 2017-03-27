# encoding: ASCII-8BIT

require 'pwnlib/context'

module Pwnlib
  module Util
    # Some fiddling methods.
    #
    # @example Call by specifying full module path.
    #   require 'pwnlib/util/fiddling'
    #   Pwnlib::Util::Fiddling.enhex('217') #=> '323137'
    # @example require 'pwn' and have all methods.
    #   require 'pwn'
    #   enhex('217') #=> '323137'
    module Fiddling
      module_function

      # Hex-encodes a string.
      #
      # @param [String] s
      #   String to be encoded.
      #
      # @return [String]
      #   Hex-encoded string.
      #
      # @example
      #   enhex('217') #=> '323137'
      def enhex(s)
        s.unpack('H*')[0]
      end

      # Hex-decodes a string.
      #
      # @param [String] s
      #   String to be decoded.
      #
      # @return [String]
      #   Hex-decoded string.
      #
      # @example
      #   unhex('353134') #=> '514'
      def unhex(s)
        [s].pack('H*')
      end

      # Present number in hex format, same as python hex() do.
      #
      # @param [Integer] n
      #   The number.
      #
      # @return [String]
      #   The hex format string.
      #
      # @example
      #   hex(0) #=> '0x0'
      #   hex(-10) #=> '-0xa'
      #   hex(0xfaceb00cdeadbeef) #=> '0xfaceb00cdeadbeef'
      def hex(n)
        (n < 0 ? '-' : '') + format('0x%x', n.abs)
      end

      # URL-encodes a string.
      #
      # @param [String] s
      #   String to be encoded.
      #
      # @return [String]
      #   URL-encoded string.
      #
      # @example
      #   urlencode('shikway') #=> '%73%68%69%6b%77%61%79'
      def urlencode(s)
        s.bytes.map { |b| format('%%%02x', b) }.join
      end

      # URL-decodes a string.
      #
      # @param [String] s
      #   String to be decoded.
      # @param [Boolean] ignore_invalid
      #   Whether invalid encoding should be ignore.
      #   If set to +true+, invalid encoding in input are left intact to output.
      #
      # @return [String]
      #   URL-decoded string.
      # @raise [ArgumentError]
      #   If +ignore_invalid+ is +false+, and there are invalid encoding in input.
      #
      # @example
      #   urldecode('test%20url') #=> 'test url'
      #   urldecode('%qw%er%ty') #=> raise ArgumentError
      #   urldecode('%qw%er%ty', true) #=> '%qw%er%ty'
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

      # Converts the argument to an array of bits.
      #
      # @param [String, Integer] s
      #   Input to be converted into bits.
      #   If input is integer, output would be padded to byte aligned.
      # @param [String] endian
      #   Endian for conversion.
      #   Can be any value accepted by context (See {Context::ContextType}).
      # @param zero
      #   Object representing a 0-bit.
      # @param one
      #   Object representing a 1-bit.
      #
      # @return [Array]
      #   An array consisting of +zero+ and +one+.
      #
      # @example
      #   bits(314) #=> [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 1, 0]
      #   bits('orz', zero: '-', one: '+').join #=> '-++-++++-+++--+--++++-+-'
      #   bits(128, endian: 'little') #=> [0, 0, 0, 0, 0, 0, 0, 1]
      def bits(s, endian: 'big', zero: 0, one: 1)
        context.local(endian: endian) do
          is_little = context.endian == 'little'
          case s
          when String
            v = 'B*'
            v.downcase! if is_little
            s.unpack(v)[0].chars.map { |ch| ch == '1' ? one : zero }
          when Integer
            # TODO(Darkpi): What should we do to negative number?
            raise ArgumentError, 's must be non-negative' unless s >= 0
            r = s.to_s(2).chars.map { |ch| ch == '1' ? one : zero }
            r.unshift(zero) until (r.size % 8).zero?
            is_little ? r.reverse : r
          else
            raise ArgumentError, 's must be either String or Integer'
          end
        end
      end

      # Simple wrapper around {#bits}, which converts output to string.
      #
      # @param (see #bits)
      #
      # @return [String]
      #   The output of {#bits} joined.
      #
      # @example
      #   bits_str('GG') #=> '0100011101000111'
      def bits_str(s, endian: 'big', zero: 0, one: 1)
        bits(s, endian: endian, zero: zero, one: one).join
      end

      # Reverse of {#bits} and {#bits_str}, convert an array of bits back to string.
      #
      # @param [String, Array<String, Integer, Boolean>] s
      #   String or array of bits to be convert back to string.
      #   <tt>[0, '0', false]</tt> represents 0-bit, and <tt>[1, '1', true]</tt> represents 1-bit.
      # @param [String] endian
      #   Endian for conversion.
      #   Can be any value accepted by context (See {Context::ContextType}).
      #
      # @return [String]
      #   A string with bits from +s+.
      # @raise [ArgumentError]
      #   If input contains value not in <tt>[0, 1, '0', '1', true, false]</tt>.
      #
      # @example
      #   unbits('0100011101000111') #=> 'GG'
      #   unbits([0, 1, 0, 1, 0, 1, 0, 0]) #=> 'T'
      #   unbits('0100011101000111', endian: 'little') #=> "\xE2\xE2"
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
          end
          [bytes.join].pack(is_little ? 'b*' : 'B*')
        end
      end

      # Reverse the bits of each byte in input string.
      #
      # @param [String] s
      #   Input string.
      #
      # @return [String]
      #   The string with bits of each byte reversed.
      #
      # @example
      #   bitswap('rb') #=> 'NF'
      def bitswap(s)
        unbits(bits(s, endian: 'big'), endian: 'little')
      end

      # Reverse the bits of a number, and returns the result as number.
      #
      # @param [Integer] n
      # @param [Integer] bits
      #   The bit length of +n+,
      #   only the lower +bits+ bits of +n+ would be used.
      #   Default to +context.bits+.
      #
      # @return [Integer]
      #   The number with bits reversed.
      #
      # @example
      #   bitswap_int(217, bits: 8) #=> 155
      def bitswap_int(n, bits: nil)
        context.local(bits: bits) do
          bits = context.bits
          n &= (1 << bits) - 1
          bits_str(n, endian: 'little').ljust(bits, '0').to_i(2)
        end
      end

      # Base64-encodes a string.
      # Do NOT contains those stupid newline (with RFC 4648).
      #
      # @param [String] s
      #   String to be encoded.
      #
      # @return [String]
      #   Base64-encoded string.
      #
      # @example
      #   b64e('desu') #=> 'ZGVzdQ=='
      def b64e(s)
        [s].pack('m0')
      end

      # Base64-decodes a string.
      #
      # @param [String] s
      #   String to be decoded.
      #
      # @return [String]
      #   Base64-decoded string.
      #
      # @example
      #   b64d('ZGVzdQ==') #=> 'desu'
      def b64d(s)
        s.unpack('m0')[0]
      end

      include ::Pwnlib::Context
    end
  end
end
