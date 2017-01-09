# encoding: ASCII-8BIT
require 'rainbow'

module Pwnlib
  module Util
    # Method for output a pretty hexdump.
    # Since this may be used in log module, to avoid cyclic dependency, it is put in a separate module as {Fiddling}
    # See {ClassMethod} for method details.
    # TODO(Darkpi): Fix example
    # TODO(Darkpi): Add test
    # @example Call by specifying full module path.
    #   require 'pwnlib/util/fiddling'
    #   Pwnlib::Util::Fiddling.enhex('217') #=> '323137'
    # @example require 'pwn' and have all methods.
    #   require 'pwn'
    #   enhex('217') #=> '323137'
    module HexDump
      # @note Do not create and call instance method here. Instead, call module method on {HexDump}.
      module ClassMethod
        MARKER = "\u2502"
        HIGHLIGHT_STYLE = ->(s) { Rainbow(s).bg(:red) }
        DEFAULT_STYLE = {
          "\x00" => ->(s) { Rainbow(s).red },
          "\x0a" => ->(s) { Rainbow(s).red },
          "\xff" => ->(s) { Rainbow(s).green },
          marker: ->(s) { Rainbow(s).gray },
          printable: ->(s) { s },
          unprintable: ->(s) { Rainbow(s).gray }
        }

        # Yields lines of a hexdump-dump of a string. Unless you have massive
        # amounts of data you probably want to use {#hexdump}.
        # Returns an Enumerator if no block given.
        #
        # @overload hexdump_iter(io, width: 16, skip: true, offset: 0, style: {}, highlight: '')
        #   @param [#read] io
        #     The object to be dumped.
        #   @param [Integer] width
        #     The max number of characters per line.
        #     It may be less if there's not enough data from io.read.
        #   @param [Boolean] skip
        #     Whether repeated lines should be replaced by a +"*"+.
        #   @param [Integer] offset
        #     Offset of the first byte to print in the left column.
        #   @param [Hash{String => Proc}] style
        #     Color scheme to use.
        #
        #     Possible keys are:
        #     * <tt>"\x00".."\xFF"</tt>, for specified byte.
        #     * +'marker'+, for the separator in right column.
        #     * +'printable'+, for printable bytes that don't have style specified.
        #     * +'unprintable'+, for unprintable bytes that don't have style specified.
        #     The proc is called with a single argument, the string to be formatted.
        #   @param [Array<String>] highlight
        #     Convenient argument to highlight (red background) some bytes in style.
        #     All elements should be a single byte string.
        #   @return [void]
        #   @yieldparam line
        #     The resulting hexdump, line by line.
        # @overload hexdump_iter(io, width: 16, skip: true, offset: 0, style: {}, highlight: '')
        #   @param [#read] io
        #     The object to be dumped.
        #   @param [Integer] width
        #     The max number of characters per line.
        #     It may be less if there's not enough data from io.read.
        #   @param [Boolean] skip
        #     Whether repeated lines should be replaced by a +"*"+.
        #   @param [Integer] offset
        #     Offset of the first byte to print in the left column.
        #   @param [Hash{String, Symbol => Proc}] style
        #     Color scheme to use. Would be merged with default style.
        #
        #     Possible keys are:
        #     * <tt>"\x00".."\xFF"</tt>, for specified byte.
        #     * +:marker+, for the separator in right column.
        #     * +:printable+, for printable bytes that don't have style specified.
        #     * +:unprintable+, for unprintable bytes that don't have style specified.
        #     The proc is called with a single argument, the string to be formatted.
        #   @param [String] highlight
        #     Convenient argument to highlight (red background) some bytes in style.
        #   @return [Enumerator]
        #     The resulting hexdump, line by line.
        def hexdump_iter(io, width: 16, skip: true, offset: 0, style: {}, highlight: '')
          return to_enum(__method__, io,
                         width: width, skip: skip, offset: offset, style:
                         style, highlight: highlight) unless block_given?

          style = DEFAULT_STYLE.merge(style)
          highlight.chars.each { |c| style[c] = HIGHLIGHT_STYLE }
          (0..255).map(&:chr).each do |c|
            next if style.include?(c)
            style[c] = (c =~ /[[:print:]]/ ? style[:printable] : style[:unprintable])
          end

          styled_bytes = (0..255).map do |b|
            left_hex = format('%02x', b)
            c = b.chr
            right_char = (c =~ /[[:print:]]/ ? c : "\u00b7")
            [style[c].call(left_hex), style[c].call(right_char)]
          end

          marker = style[:marker].call(MARKER)
          spacer = ' '

          byte_index = offset
          skipping = false
          last_chunk = ''

          loop do
            # We assume that chunk is in ASCII-8BIT encoding.
            chunk = io.read(width)
            break unless chunk
            chunk_bytes = chunk.bytes
            start_byte_index = byte_index
            byte_index += chunk_bytes.size

            # Yield * once for repeated lines.
            if skip && last_chunk == chunk
              yield '*' unless skipping
              skipping = true
              next
            end
            skipping = false
            last_chunk = chunk

            hex_bytes = ''
            printable = ''
            chunk_bytes.each_with_index do |b, i|
              left_hex, right_char = styled_bytes[b]
              hex_bytes << left_hex
              printable << right_char
              if i % 4 == 3 && i != chunk_bytes.size - 1
                hex_bytes << spacer
                printable << marker
              end
              hex_bytes << ' '
            end

            if chunk_bytes.size < width
              padded_hex_length = 3 * width + (width - 1) / 4
              hex_length = 3 * chunk_bytes.size + (chunk_bytes.size - 1) / 4
              hex_bytes << ' ' * (padded_hex_length - hex_length)
            end

            yield format("%08x  %s #{MARKER}%s#{MARKER}", start_byte_index, hex_bytes, printable)
          end

          yield format('%08x', byte_index)
        end

        # Returns a hexdump-dump of a string.
        # @param [String] str
        #   string to be hexdump
        # @param [Integer] width
        #   The number of characters per line.
        # @param [Boolean] skip
        #   Whether repeated lines should be replaced by a +"*"+.
        # @param [Integer] offset
        #   Offset of the first byte to print in the left column.
        # @param [Hash{String, Symbol => Proc}] style
        #   Color scheme to use. Would be merged with default style.
        #
        #   Possible keys are:
        #   * <tt>"\x00".."\xFF"</tt>, for specified byte.
        #   * +:marker+, for the separator in right column.
        #   * +:printable+, for printable bytes that don't have style specified.
        #   * +:unprintable+, for unprintable bytes that don't have style specified.
        #   The proc is called with a single argument, the string to be formatted.
        # @param [String] highlight
        #   Convenient argument to highlight (red background) some bytes in style.
        # @return [String]
        #   The resulting hexdump.
        def hexdump(str, width: 16, skip: true, offset: 0, style: {}, highlight: '')
          hexdump_iter(StringIO.new(str),
                       width: width, skip: skip, offset: offset, style: style,
                       highlight: highlight).to_a.join("\n")
        end
      end

      extend ClassMethod
    end
  end
end
