# encoding: ASCII-8BIT

require 'elftools'
require 'keystone_engine/keystone_const'
require 'tempfile'

require 'pwnlib/context'
require 'pwnlib/errors'
require 'pwnlib/util/ruby'

module Pwnlib
  # Convert assembly code to machine code and vice versa.
  # Use two open-source projects +keystone+/+capstone+ to asm/disasm.
  module Asm
    module_function

    # Default virtaul memory base address of architectures.
    DEFAULT_VMA = {
      i386: 0x08048000,
      amd64: 0x400000
    }.freeze

    # Disassembles a bytestring into human readable assembly.
    #
    # {.disasm} depends on another open-source project - capstone, error will be raised if capstone is not intalled.
    # @param [String] data
    #   The bytestring.
    # @param [Integer] vma
    #   Virtual memory address.
    #
    # @return [String]
    #   Disassemble result with nice typesetting.
    #
    # @raise [Pwnlib::Errors::DependencyError]
    #   If libcapstone is not installed.
    #
    # @example
    #   context.arch = 'i386'
    #   print disasm("\xb8\x5d\x00\x00\x00")
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

    # Convert assembly code to machine code.
    #
    # @param [String] code
    #   The assembly code to be converted.
    #
    # @return [String]
    #   The result.
    #
    # @example
    #   assembly = shellcraft.amd64.linux.sh
    #   context.local(arch: 'amd64') { asm(assembly) }
    #   #=> "jhH\xB8/bin///sPj;XH\x89\xE71\xF6\x99\x0F\x05"
    #
    #   context.local(arch: 'i386') { asm(shellcraft.sh) }
    #   #=> "jhh///sh/binj\vX\x89\xE31\xC9\x99\xCD\x80"
    #
    # @diff
    #   Not support +asm('mov eax, SYS_execve')+.
    def asm(code)
      require_message('keystone_engine', install_keystone_guide)
      KeystoneEngine::Ks.new(ks_arch, ks_mode).asm(code)[0]
    end

    # Builds an ELF file from executable code.
    #
    # @param [String] data
    #   Assembled code.
    # @param [Integer?] vma
    #   Load address for the ELF file.
    #   If +nil+ is given, default address will be used.
    #   See {DEFAULT_VMA}.
    # @param [Boolean] extract
    #   Returns ELF content or the path to the ELF file.
    #   If +false+ is given, the ELF will be saved into a temp file, and the path is returned.
    #   Otherwise, the content of ELF is returned.
    #
    # @return [String]
    #   If +extract+ is +true+ (default), returns the content of ELF. Otherwise, a file is created and the path of it is
    #   returned.
    #
    # @diff
    #   Unlike pwntools-python uses cross-compiler to compile codes into ELF, we create ELF(s) in pure Ruby
    #   implementation, to have higher flexibility and less binary dependencies.
    def make_elf(data, vma: nil, extract: true)
      vma ||= DEFAULT_VMA[context.arch.to_sym]
      vma &= -PAGE_SIZE
      # ELF header
      # Program headers
      # Section headers
      # <data>
      headers = create_elf_headers(vma)
      ehdr = headers[:elf_header]
      phdr = headers[:program_header]
      entry = ehdr.num_bytes + phdr.num_bytes
      ehdr.e_entry = entry + phdr.p_vaddr
      ehdr.e_phoff = ehdr.num_bytes
      phdr.p_filesz = phdr.p_memsz = entry + data.size
      elf = ehdr.to_binary_s + phdr.to_binary_s + data
      return elf if extract
      temp = Dir::Tmpname.create(['pwn', '.elf']) {}
      File.open(temp, 'wb', 0750) { |f| f.write(elf) }
      temp
    end

    ::Pwnlib::Util::Ruby.private_class_method_block do
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

      def ks_arch
        {
          'i386' => KeystoneEngine::KS_ARCH_X86,
          'amd64' => KeystoneEngine::KS_ARCH_X86
        }[context.arch]
      end

      def ks_mode
        {
          32 => KeystoneEngine::KS_MODE_32,
          64 => KeystoneEngine::KS_MODE_64
        }[context.bits]
      end

      # FFI is used in keystone and capstone binding gems, this method handles when libraries not installed yet.
      def require_message(lib, msg)
        require lib
      rescue LoadError => e
        raise ::Pwnlib::Errors::DependencyError, e.message + "\n\n" + msg
      end

      def install_crabstone_guide
        <<-EOS
#disasm dependes on capstone, which is detected not installed yet.
Checkout the following link for installation guide:

http://www.capstone-engine.org/documentation.html

        EOS
      end

      def install_keystone_guide
        <<-EOS
#asm dependes on keystone, which is detected not installed yet.
Checkout the following link for installation guide:

https://github.com/keystone-engine/keystone/tree/master/docs

        EOS
      end

      # build headers according to context.arch/bits/endian
      def create_elf_headers(vma)
        elf_header = create_elf_header
        # we only need one LOAD segment
        program_header = create_program_header(vma)
        elf_header.e_phentsize = program_header.num_bytes
        elf_header.e_phnum = 1
        {
          elf_header: elf_header,
          program_header: program_header
        }
      end

      def create_elf_header
        header = ::ELFTools::Structs::ELF_Ehdr.new(endian: endian)
        # this decide size of entries
        header.elf_class = context.bits
        header.e_ident.magic = ::ELFTools::Constants::ELFMAG
        header.e_ident.ei_class = { 32 => 1, 64 => 2 }[context.bits]
        header.e_ident.ei_data = { little: 1, big: 2 }[endian]
        # Not sure what version field means, seems it can be any value.
        header.e_ident.ei_version = 1
        header.e_ident.ei_padding = "\x00" * 7
        # TODO(david942j): support create a shared object
        header.e_type = ::ELFTools::Constants::ET::ET_EXEC
        header.e_machine = e_machine
        header.e_ehsize = header.num_bytes
        header
      end

      # Size of one page, where is the best place to define this constant?
      PAGE_SIZE = 0x1000
      def create_program_header(vma)
        header = ::ELFTools::Structs::ELF_Phdr[context.bits].new(endian: endian)
        header.p_type = ::ELFTools::Constants::PT::PT_LOAD
        header.p_offset = 0
        header.p_vaddr = vma
        header.p_paddr = vma
        header.p_flags = 4 | 1 # r-x
        header.p_align = PAGE_SIZE
        header
      end

      # Mapping +context.arch+ to +::ELFTools::Constants::EM::EM_*+.
      ARCH_EM = {
        aarch64: 'AARCH64',
        alpha: 'ALPHA',
        amd64: 'X86_64',
        arm: 'ARM',
        cris: 'CRIS',
        i386: '386',
        ia64: 'IA_64',
        m68k: '68K',
        mips64: 'MIPS',
        mips: 'MIPS',
        powerpc64: 'PPC64',
        powerpc: 'PPC',
        s390: 'S390',
        sparc64: 'SPARCV9',
        sparc: 'SPARC',
      }.freeze
      def e_machine
        const = ARCH_EM[context.arch.to_sym]
        # TODO(david942j): raise UnsupportedArchError
        return ::ELFTools::Constants::EM::EM_NONE if const.nil?
        ::ELFTools::Constants::EM.const_get("EM_#{const}")
      end

      def endian
        context.endian.to_sym
      end

      include ::Pwnlib::Context
    end
  end
end
