# encoding: ASCII-8BIT
require 'pwnlib/context'
require 'crabstone'

module Pwnlib
  # Convert assembly code to machine code and vice versa.
  # Use two open-source projects +keystone+/+capstone+ to asm/disasm.
  module Asm
    # @note Do not create and call instance method here.
    module ClassMethods
      # Disassembles a bytestring into human readable assembler.
      #
      # @param [String] data The bytestring.
      # @param [Integer] vma Virtual memory address.
      # @return [String] Disassemble result with nice typesetting.
      # @example
      #   context.arch = 'i386'
      #   print disasm("\xb8\x5d\x00\x00")
      #   #   0:   b8 5d 00 00 00 mov     eax, 0x5d
      #
      #   context.arch = 'amd64'
      #   print disasm("\xb8\x17\x00\x00\x00")
      #   #   0:   b8 17 00 00 00 mov     eax, 0x17
      def disasm(data, vma: 0)
        cs = Crabstone::Disassembler.new(cap_arch, cap_mode)
        insts = cs.disasm(data, vma).map do |ins|
          [ins.address, ins.bytes.pack('C*'), ins.mnemonic, ins.op_str.to_s]
        end
        max_dlen = format('%x', insts.last.first).size + 2
        max_hlen = insts.map { |ins| ins[1].size }.max * 3
        insts.reduce('') do |s, ins|
          hex_code = ins[1].bytes.map { |c| format('%02x', c) }.join(' ')
          inst = if ins[3].empty?
                   ins[2]
                 else
                   format('%-7s %s', ins[2], ins[3])
                 end
          s + format("%#{max_dlen}x:   %-#{max_hlen}s%s\n", ins[0], hex_code, inst)
        end
      end

      private

      def cap_arch
        {
          'i386' => Crabstone::ARCH_X86,
          'amd64' => Crabstone::ARCH_X86
        }[context.arch]
      end

      def cap_mode
        {
          32 => Crabstone::MODE_32,
          64 => Crabstone::MODE_64
        }[context.bits]
      end
      include ::Pwnlib::Context
    end

    extend ClassMethods
  end
end
