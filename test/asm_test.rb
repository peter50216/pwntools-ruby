# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/asm'
require 'pwnlib/shellcraft/shellcraft'

class AsmTest < MiniTest::Test
  include ::Pwnlib::Context
  Asm = ::Pwnlib::Asm

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def skip_windows
    skip 'Not test asm/disasm on Windows' if TTY::Platform.new.windows?
  end

  def linux_only
    skip 'ELF can only be executed on Linux' unless TTY::Platform.new.linux?
  end

  def test_i386_asm
    skip_windows
    context.local(arch: 'i386') do
      assert_equal("\x90", Asm.asm('nop'))
      assert_equal("\xeb\xfe", Asm.asm(@shellcraft.infloop))
      assert_equal("jhh///sh/binj\x0bX\x89\xe31\xc9\x99\xcd\x80", Asm.asm(@shellcraft.sh))
      # issue #51
      assert_equal("j\x01\xfe\x0c$h\x01\x01\x01\x01\x814$\xf2\xf3\x0b\xfe",
                   Asm.asm(@shellcraft.pushstr("\xf3\xf2\x0a\xff")))
    end
  end

  def test_amd64_asm
    skip_windows
    context.local(arch: 'amd64') do
      assert_equal("\x90", Asm.asm('nop'))
      assert_equal("\xeb\xfe", Asm.asm(@shellcraft.infloop))
      assert_equal("jhH\xb8/bin///sPj;XH\x89\xe71\xf6\x99\x0f\x05", Asm.asm(@shellcraft.sh))
      assert_equal("j\x01\xfe\x0c$H\xb8\x01\x01\x01\x01\x01\x01\x01\x01PH\xb8\xfe\xfe\xfe\xfe\xfe\xfe\x0b\xfeH1\x04$",
                   Asm.asm(@shellcraft.pushstr("\xff\xff\xff\xff\xff\xff\x0a\xff")))
    end
  end

  def test_i386_disasm
    skip_windows
    context.local(arch: 'i386') do
      str = Asm.disasm("h\x01\x01\x01\x01\x814$ri\x01\x011\xd2"\
                       "Rj\x04Z\x01\xe2R\x89\xe2jhh///sh/binj\x0bX\x89\xe3\x89\xd1\x99\xcd\x80")
      assert_equal(<<-EOS, str)
   0:   68 01 01 01 01       push    0x1010101
   5:   81 34 24 72 69 01 01 xor     dword ptr [esp], 0x1016972
   c:   31 d2                xor     edx, edx
   e:   52                   push    edx
   f:   6a 04                push    4
  11:   5a                   pop     edx
  12:   01 e2                add     edx, esp
  14:   52                   push    edx
  15:   89 e2                mov     edx, esp
  17:   6a 68                push    0x68
  19:   68 2f 2f 2f 73       push    0x732f2f2f
  1e:   68 2f 62 69 6e       push    0x6e69622f
  23:   6a 0b                push    0xb
  25:   58                   pop     eax
  26:   89 e3                mov     ebx, esp
  28:   89 d1                mov     ecx, edx
  2a:   99                   cdq
  2b:   cd 80                int     0x80
      EOS
      assert_equal(<<-EOS, Asm.disasm("\xb8\x5d\x00\x00\x00"))
  0:   b8 5d 00 00 00 mov     eax, 0x5d
      EOS
    end
  end

  def test_amd64_disasm
    skip_windows
    context.local(arch: 'amd64') do
      str = Asm.disasm("hri\x01\x01\x814$\x01\x01\x01\x011\xd2" \
                       "Rj\x08ZH\x01\xe2RH\x89\xe2jhH\xb8/bin///sPj;XH\x89\xe7H\x89\xd6\x99\x0f\x05", vma: 0xfff)

      assert_equal(<<-EOS, str)
   fff:   68 72 69 01 01                push    0x1016972
  1004:   81 34 24 01 01 01 01          xor     dword ptr [rsp], 0x1010101
  100b:   31 d2                         xor     edx, edx
  100d:   52                            push    rdx
  100e:   6a 08                         push    8
  1010:   5a                            pop     rdx
  1011:   48 01 e2                      add     rdx, rsp
  1014:   52                            push    rdx
  1015:   48 89 e2                      mov     rdx, rsp
  1018:   6a 68                         push    0x68
  101a:   48 b8 2f 62 69 6e 2f 2f 2f 73 movabs  rax, 0x732f2f2f6e69622f
  1024:   50                            push    rax
  1025:   6a 3b                         push    0x3b
  1027:   58                            pop     rax
  1028:   48 89 e7                      mov     rdi, rsp
  102b:   48 89 d6                      mov     rsi, rdx
  102e:   99                            cdq
  102f:   0f 05                         syscall
      EOS
      assert_equal(<<-EOS, Asm.disasm("\xb8\x17\x00\x00\x00"))
  0:   b8 17 00 00 00 mov     eax, 0x17
      EOS
    end
  end

  # To ensure coverage
  def test_require
    err = assert_raises(::Pwnlib::Errors::DependencyError) do
      Asm.__send__(:require_message, 'no_such_lib', 'meow')
    end
    assert_match(/meow/, err.message)
  end

  def make_elf_file(*args)
    elf = Asm.make_elf(*args)
    stream = StringIO.new(elf)
    [elf, ::ELFTools::ELFFile.new(stream)]
  end

  def test_make_elf
    # create ELF and use ELFTools to test it
    data = 'not important'
    elf, elf_file = make_elf_file(data)
    assert_equal('Intel 80386', elf_file.machine)
    # check entry point contains data
    assert_equal(data, elf[elf_file.header.e_entry - 0x08048000, data.size])
    segment = elf_file.segments.first
    assert(segment.readable? && segment.executable?)

    # test to_file
    temp_path = Asm.make_elf(data, to_file: true)
    assert_equal(elf, IO.binread(temp_path))
    File.unlink(temp_path)

    # test block form
    temp_path = Asm.make_elf(data) do |path|
      assert(File.file?(path))
      path
    end
    # check file removed
    refute(File.exist?(temp_path))

    # test vma
    custom_base = 0x1234000
    _, elf_file = make_elf_file(data, vma: custom_base)
    assert_equal(custom_base, elf_file.segments.first.header.p_vaddr)

    context.local(arch: :arm) do
      _, elf_file = make_elf_file(data)
      assert_equal(32, elf_file.header.elf_class)
      assert_equal('ARM', elf_file.machine)
      assert_equal(0x8000, elf_file.segments.first.header.p_vaddr)
    end

    context.local(arch: :vax) do
      err = assert_raises(::Pwnlib::Errors::UnsupportedArchError) do
        Asm.make_elf('')
      end
      assert_equal('Unknown machine type of architecture "vax".', err.message)
    end
  end

  # this test can be removed after method +run_shellcode+ being implemented
  def test_make_elf_and_run
    # run the ELF we created to make sure it works.
    linux_only

    # test supported architecture
    {
      i386: /08048000-08049000 r-xp/,
      amd64: /00400000-00401000 r-xp/
    }.each do |arch, regexp|
      context.local(arch: arch) do
        data = Asm.asm(@shellcraft.cat('/proc/self/maps') + @shellcraft.syscall('SYS_exit', 0))
        Asm.make_elf(data) do |path|
          Open3.popen2(path) do |_i, o, _t|
            assert_match(regexp, o.gets)
          end
        end
      end
    end
  end
end
