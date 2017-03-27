# encoding: ASCII-8BIT

require 'rainbow'

module Pwnlib
  module Util
    # Method for output a pretty hexdump.
    # Since this may be used in log module, to avoid cyclic dependency, it is put in a separate module as {Fiddling}
    #
    # @todo Control coloring by context.
    #
    # @example Call by specifying full module path.
    #   require 'pwnlib/util/hexdump'
    #   Pwnlib::Util::HexDump.hexdump('217')
    #   #=> "00000000  32 31 37                  │217│\n00000003"
    # @example require 'pwn' and have all methods.
    #   require 'pwn'
    #   hexdump('217')
    #   #=> "00000000  32 31 37                  │217│\n00000003"
    module HexDump
      MARKER = "\u2502".freeze
      HIGHLIGHT_STYLE = ->(s) { Rainbow(s).bg(:red) }
      DEFAULT_STYLE = {
        0x00 => ->(s) { Rainbow(s).red },
        0x0a => ->(s) { Rainbow(s).red },
        0xff => ->(s) { Rainbow(s).green },
        marker: ->(s) { Rainbow(s).dimgray },
        printable: ->(s) { s },
        unprintable: ->(s) { Rainbow(s).dimgray }
      }.freeze

      module_function

      # @!macro [new] hexdump_options
      #   Color is provided using +rainbow+ gem and only when output is a tty.
      #   To force enable/disable coloring, call <tt>Rainbow.enabled = true / false</tt>.
      #   @param [Integer] width
      #     The max number of characters per line.
      #   @param [Boolean] skip
      #     Whether repeated lines should be replaced by a +"*"+.
      #   @param [Integer] offset
      #     Offset of the first byte to print in the left column.
      #   @param [Hash{Integer, Symbol => Proc}] style
      #     Color scheme to use.
      #
      #     Possible keys are:
      #     * <tt>0x00..0xFF</tt>, for specified byte.
      #     * +:marker+, for the separator in right column.
      #     * +:printable+, for printable bytes that don't have style specified.
      #     * +:unprintable+, for unprintable bytes that don't have style specified.
      #     The proc is called with a single argument, the string to be formatted.
      #   @param [String] highlight
      #     Convenient argument to highlight (red background) some bytes in style.

      # Yields lines of a hexdump-dump of a string.
      # Unless you have massive amounts of data you probably want to use {#hexdump}.
      # Returns an Enumerator if no block given.
      #
      # @param [#read] io
      #   The object to be dumped.
      # @!macro hexdump_options
      #
      # @return [Enumerator<String>]
      #   The resulting hexdump, line by line.
      def hexdump_iter(io, width: 16, skip: true, offset: 0, style: {}, highlight: '')
        Enumerator.new do |y|
          style = DEFAULT_STYLE.merge(style)
          highlight.bytes.each { |b| style[b] = HIGHLIGHT_STYLE }
          (0..255).each do |b|
            next if style.include?(b)
            style[b] = (b.chr =~ /[[:print:]]/ ? style[:printable] : style[:unprintable])
          end

          styled_bytes = (0..255).map do |b|
            left_hex = format('%02x', b)
            c = b.chr
            right_char = (c =~ /[[:print:]]/ ? c : "\u00b7")
            [style[b].call(left_hex), style[b].call(right_char)]
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
              y << '*' unless skipping
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

            y << format("%08x  %s #{MARKER}%s#{MARKER}", start_byte_index, hex_bytes, printable)
          end

          y << format('%08x', byte_index)
        end
      end

      # Returns a hexdump-dump of a string.
      #
      # @param [String] str
      #   The string to be hexdumped.
      # @!macro hexdump_options
      #
      # @return [String]
      #   The resulting hexdump.
      def hexdump(str, width: 16, skip: true, offset: 0, style: {}, highlight: '')
        hexdump_iter(StringIO.new(str),
                     width: width, skip: skip, offset: offset, style: style,
                     highlight: highlight).to_a.join("\n")
      end
    end
  end
end
