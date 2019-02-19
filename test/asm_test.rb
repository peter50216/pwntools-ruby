# encoding: ASCII-8BIT

require 'test_helper'

require 'pwnlib/asm'
require 'pwnlib/shellcraft/shellcraft'
require 'pwnlib/tubes/process'

class AsmTest < MiniTest::Test
  include ::Pwnlib::Context
  Asm = ::Pwnlib::Asm

  def setup
    @shellcraft = ::Pwnlib::Shellcraft::Shellcraft.instance
  end

  def parse_sfile(filename)
    # First line is architecture
    lines = File.readlines(filename)
    metadata = lines.shift
                    .delete('#')
                    .split(',').map { |c| c.split(':', 2).map(&:strip) }
                    .map { |k, v| [k.to_sym, v] }
                    .to_h
    lines.reject { |l| l.start_with?('#') }.join.split("\n\n").each do |test|
      # fetch `<vma>:`
      vma = test.scan(/^\s*(\w+):/).flatten.first.to_i(16)
      # fetch bytes
      bytes = [test.scan(/^\s*\w+:\s{3}(([\da-f]{2}\s)+)\s/).map(&:first).join.split.join].pack('H*')
      output = test
      output << "\n" unless output.end_with?("\n")
      yield(bytes, vma, test, **metadata)
    end
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

  # All tests of disasm can be found under test/data/assembly/<arch>.s.
  Dir.glob(File.join(__dir__, 'data', 'assembly', '*.s')) do |file|
    # Defining methods dynamically makes proper error message shown when tests failed.
    __send__(:define_method, "test_disasm_file_#{File.basename(file, '.s')}") do
      skip_windows
      parse_sfile(file) do |bytes, vma, output, **ctx|
        context.local(**ctx) do
          assert_equal(output, Asm.disasm(bytes, vma: vma))
        end
      end
    end
  end

  def test_disasm_unsupported
    err = context.local(arch: :vax) do
      assert_raises(::Pwnlib::Errors::UnsupportedArchError) { Asm.disasm('') }
    end
    assert_equal('Disasm on architecture "vax" is not supported yet.', err.message)
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
    linux_only('ELF can only be executed on Linux')

    # test supported architecture
    {
      i386: /08048000-08049000 rwxp/,
      amd64: /00400000-00401000 rwxp/
    }.each do |arch, regexp|
      context.local(arch: arch) do
        data = Asm.asm(@shellcraft.cat('/proc/self/maps') + @shellcraft.syscall('SYS_exit', 0))
        Asm.make_elf(data) do |path|
          assert_match(regexp, ::Pwnlib::Tubes::Process.new(path).gets)
        end
      end
    end
  end
end
