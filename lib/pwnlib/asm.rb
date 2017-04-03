# encoding: ASCII-8BIT
require 'pwnlib/context'

module Pwnlib
  # Convert assembly code to machine code and vice versa.
  # Use two open-source projects +keystone+/+capstone+ to asm/disasm.
  module Asm
    # @note Do not create and call instance method here.
    module ClassMethods
      # Disassembles a bytestring into human readable assembly.
      #
      # {#disasm} depends on another open-source project - capstone, error will be raised if capstone is not intalled.
      # @param [String] data
      #   The bytestring.
      # @param [Integer] vma
      #   Virtual memory address.
      #
      # @return [String]
      #   Disassemble result with nice typesetting.
      #
      # @raise [LoadError]
      #   If libcapstone is not installed.
      #
      # @example
      #   context.arch = 'i386'
      #   print disasm("\xb8\x5d\x00\x00")
      #   #   0:   b8 5d 00 00 00 mov     eax, 0x5d
      #
      #   context.arch = 'amd64'
      #   print disasm("\xb8\x17\x00\x00\x00")
      #   #   0:   b8 17 00 00 00 mov     eax, 0x17
      #   print disasm("jhH\xb8/bin///sPH\x89\xe71\xd21\xf6j;X\x0f\x05", vma: 0x1000)
      #   #  1000:   6a 68                         push    0x68
      #   #  1002:   48 b8 2f 62 69 6e 2f 2f 2f 73 movabs  rax, 0x732f2f2f6e69622f
      #   #  100c:   50                            push    rax
      #   #  100d:   48 89 e7                      mov     rdi, rsp
      #   #  1010:   31 d2                         xor     edx, edx
      #   #  1012:   31 f6                         xor     esi, esi
      #   #  1014:   6a 3b                         push    0x3b
      #   #  1016:   58                            pop     rax
      #   #  1017:   0f 05                         syscall
      def disasm(data, vma: 0)
        require_message('crabstone', install_crabstone_guide) # will raise error if require fail.
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

      # FFI is used in keystone and capstone binding gems, this method handles when libraries not installed yet.
      def require_message(lib, msg)
        require lib
      rescue LoadError => e
        raise LoadError, e.message + "\n\n" + msg
      end

      def install_crabstone_guide
        <<-EOS
#disasm dependes on capstone, which is detected not installed yet.
Checkout the following link for installation guide:

http://www.capstone-engine.org/documentation.html

        EOS
      end
      include ::Pwnlib::Context
    end

    extend ClassMethods
  end
end
