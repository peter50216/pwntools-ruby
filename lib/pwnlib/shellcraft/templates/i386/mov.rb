# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/registers'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/packing'

# Move +src+ into +dest+ without newlines and null bytes.
::Pwnlib::Shellcraft.define(__FILE__) do |dest, src, stack_allowed: true|
  extend ::Pwnlib::Shellcraft::Registers
  extend ::Pwnlib::Util::Fiddling
  extend ::Pwnlib::Util::Packing

  raise ArgumentError, "#{dest} is not a register" unless register?(dest)
  dest = get_register(dest)
  raise ArgumentError "cannot use #{dest} on i386" if dest.size > 32 || dest.is64bit
  if register?(src)
    src = get_register(src)
    raise ArgumentError "cannot use #{src} on i386" if src.size > 32 || src.is64bit
    if dest.size < src.size && !dest.bigger.include?(src.name)
      raise ArgumentError, "cannot mov #{dest}, #{src}: dest is smaller than src"
    end
  else
    context.local(arch: 'i386') { src = evaluate(src) }
    raise ArgumentError, format('cannot mov %s, %d: dest is smaller than src', dest, src) unless dest.fits(src)

    # Calculate the packed version
    srcp = pack(src & ((1 << dest.size) - 1), bits: dest.size)

    # Calculate the unsigned and signed versions
    srcu = unpack(srcp, bits: dest.size, signed: false)
    srcs = unpack(srcp, bits: dest.size, signed: true)
    srcp_neg = p32(-src)
    srcp_not = p32(src ^ 0xffffffff)
  end
  if register?(src)
    if src == dest || dest.bigger.include?(src.name)
      cat "/* moving #{src} into #{dest}, but this is a no-op */"
    elsif dest.size > src.size
      cat "movzx #{dest}, #{src}"
    else
      cat "mov #{dest}, #{src}"
    end
  elsif src.is_a?(Numeric) # Constant or immi
    xor = ->(dst) { "xor #{dst.xor}, #{dst.xor}" }
    if src.zero? # special case for zeroes
      cat "xor #{dest}, #{dest} /* #{src} */"
    elsif stack_allowed && dest.size == 32 && src == 10
      cat "push 9 /* mov #{dest}, '\\n' */"
      cat "pop #{dest}"
      cat "inc #{dest}"
    elsif stack_allowed && dest.size == 32 && (-2**7 <= srcs && srcs < 2**7) && okay(srcp[0])
      cat "push #{pretty(src)}"
      cat "pop #{dest}"
    elsif okay(srcp)
      # Easy case. This implies that the register size and value are the same.
      cat "mov #{dest}, #{pretty(src)}"
    elsif srcu < 2**8 && okay(srcp[0]) && dest.sizes.include?(8)
      # Move 8-bit value into reg.
      cat xor[dest]
      cat "mov #{dest.sizes[8]}, #{pretty(src)}"
    elsif srcu == srcu & 0xff00 && okay(srcp[1]) && dest.ff00
      # Target value is a 16-bit value with no data in the low 8 bits means we can use the 'AH' style register.
      cat xor[dest]
      cat "mov #{dest.ff00}, #{pretty(src)} >> 8"
    elsif srcu < 2**16 && okay(srcp[0, 2])
      # Target value is a 16-bit value, use a 16-bit mov.
      cat xor[dest]
      cat "mov #{dest.sizes[16]}, #{pretty(src)}"
    elsif okay(srcp_neg)
      cat "mov #{dest}, -#{pretty(src)}"
      cat "neg #{dest}"
    elsif okay(srcp_not)
      cat "mov #{dest}, (-1) ^ #{pretty(src)}"
      cat "not #{dest}"
    else
      # All else has failed.  Use some XOR magic to move things around.
      a, b = xor_pair(srcp, avoid: "\x00\n")
      a = hex(unpack(a, bits: dest.size))
      b = hex(unpack(b, bits: dest.size))
      cat "mov #{dest}, #{a}"
      cat "xor #{dest}, #{b} /* #{hex(src)} == #{a} ^ #{b} */"
    end
  end
end
