# encoding: ASCII-8BIT

require 'bindata'

require 'pwnlib/context'

module Pwnlib
  module Util
    # Helper methods related to getdents syscall.
    module Getdents
      # For inverse mapping of +linux_dirent#d_type+. +man getdents+ to see more information.
      DT_TYPE_INVERSE = {
        0 => 'UNKNOWN',
        1 => 'FIFO',
        2 => 'CHR',
        4 => 'DIR',
        6 => 'BLK',
        8 => 'REG',
        10 => 'LNK',
        12 => 'SOCK'
      }.freeze

      # The +linux_dirent+ structure.
      class Dirent < ::BinData::Record
        attr_accessor :bits
        # struct linux_dirent {
        #   unsigned long  d_ino;     /* Inode number */
        #   unsigned long  d_off;     /* Offset to next linux_dirent */
        #   unsigned short d_reclen;  /* Length of this linux_dirent */
        #   char           d_name[];  /* Filename (null-terminated) */
        #                     /* length is actually (d_reclen - 2 -
        #                        offsetof(struct linux_dirent, d_name)) */
        #   /*
        #   char           pad;       // Zero padding byte
        #   char           d_type;    // File type (only since Linux
        #                             // 2.6.4); offset is (d_reclen - 1)
        #   */
        # }
        endian :big_and_little
        choice :d_ino, selection: :bits, choices: { 32 => :uint32, 64 => :uint64 }
        choice :d_off, selection: :bits, choices: { 32 => :uint32, 64 => :uint64 }
        uint16 :d_reclen
        string :d_name, read_length: -> { d_reclen - d_ino.num_bytes - d_off.num_bytes - 4 }
        int8 :pad
        int8 :d_type
      end

      module_function

      # Parse the output of getdents syscall.
      # For users to handle the shit-like output by +shellcraft.ls+.
      #
      # @param [String] binstr
      #   The content returns by getdents syscall.
      #
      # @return [String]
      #   Formatted output of filenames with file types.
      #
      # @example
      #   context.arch = 'i386'
      #   Util::Getdents.parse("\x92\x22\x0e\x01\x8f\x4a\xb3\x41" \
      #                         "\x18\x00\x52\x45\x41\x44\x4d\x45" \
      #                         "\x2e\x6d\x64\x00\x00\x00\x00\x08" \
      #                         "\xb5\x10\x34\x01\xff\xff\xff\x7f" \
      #                         "\x10\x00\x6c\x69\x62\x00\x00\x04")
      #   #=> "REG README.md\nDIR lib\n"
      def parse(binstr)
        str = StringIO.new(binstr)
        result = StringIO.new
        until str.eof?
          ent = Dirent.new(endian: context.endian.to_sym)
          ent.bits = context.bits
          ent.read(str)
          # Note: d_name might contains garbage after first "\x00", so we use gsub(/\x00.*/) instead of delete("\x00").
          result.puts(DT_TYPE_INVERSE[ent.d_type] + ' ' + ent.d_name.gsub(/\x00.*/, ''))
        end
        result.string
      end

      include ::Pwnlib::Context
    end
  end
end
