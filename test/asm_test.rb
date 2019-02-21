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
    File.read(filename).split("\n\n").each do |it|
      lines = it.lines
      metadata = {}
      # First line of +lines+ might be the extra context setting
      if lines.first.start_with?('# context: ')
        # "# context: arch: a, endian: big"
        # => { arch: 'a', endian: 'big' }
        metadata = lines.shift.slice(11..-1)
                        .split(',').map { |c| c.split(':', 2).map(&:strip) }
                        .map { |k, v| [k.to_sym, v] }.to_h
      end
      comment, output = lines.partition { |l| l =~ /^\s*[;#]/ }.map(&:join)
      next if output.empty?

      output << "\n" unless output.end_with?("\n")
      tests = output.lines.map do |l|
        vma, hex_code, _dummy, inst = l.scan(/^\s*(\w+):\s{3}(([\da-f]{2}\s)+)\s+(.*)$/).first
        [vma.to_i(16), hex_code.split.join, inst.strip]
      end

      vma = tests.first.first
      bytes = [tests.map { |l| l[1] }.join].pack('H*')
      insts = tests.map(&:last)
      yield(bytes, vma, insts, output, comment, **metadata)
    end
  end

  # All tests of asm can be found under test/data/assembly/<arch>.s.
  %w[aarch64 amd64 arm i386 mips mips64 powerpc powerpc64 sparc sparc64 thumb].each do |arch|
    file = File.join(__dir__, 'data', 'assembly', arch + '.s')
    # Defining methods dynamically makes proper error message shown when tests failed.
    __send__(:define_method, "test_asm_#{arch}") do
      skip_windows

      context.local(arch: arch) do
        parse_sfile(file) do |bytes, vma, insts, _output, comment, **ctx|
          next if comment.include?('!skip asm')

          context.local(**ctx) do
            assert_equal(bytes, Asm.asm(insts.join("\n"), vma: vma))
          end
        end
      end
    end
  end

  def test_asm_unsupported
    skip_windows

    err = context.local(arch: :vax) do
      assert_raises(::Pwnlib::Errors::UnsupportedArchError) { Asm.asm('') }
    end
    assert_equal('Asm on architecture "vax" is not supported yet.', err.message)
  end

  # All tests of disasm can be found under test/data/assembly/<arch>.s.
  %w[aarch64 amd64 arm i386 mips mips64 powerpc64 sparc sparc64 thumb].each do |arch|
    file = File.join(__dir__, 'data', 'assembly', arch + '.s')
    # Defining methods dynamically makes proper error message shown when tests failed.
    __send__(:define_method, "test_disasm_#{arch}") do
      skip_windows

      context.local(arch: arch) do
        parse_sfile(file) do |bytes, vma, _insts, output, comment, **ctx|
          next if comment.include?('!skip disasm')

          context.local(**ctx) do
            assert_equal(output, Asm.disasm(bytes, vma: vma))
          end
        end
      end
    end
  end

  def test_disasm_unsupported
    skip_windows

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
