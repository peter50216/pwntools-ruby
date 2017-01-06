require 'pwnlib/util/packing'
extend ::Pwnlib::Util::Packing::ClassMethod
require 'pwnlib/util/fiddling'
extend ::Pwnlib::Util::Fiddling::ClassMethod
require 'pwnlib/shellcraft/registers'
extend ::Pwnlib::Shellcraft::Registers::ClassMethod
require 'pwnlib/shellcraft/shellcraft'

def mov(dest, src, stack_allowed: true)
  raise ArgumentError, "#{dest} is not a register" unless register?(dest)
  dest = get_register(dest)
  if register?(src)
    src = get_register(src)
    if dest.size < src.size && !dest.bigger.include?(src.name)
      raise ArgumentError, "cannot mov #{dest}, #{src}: dest is smaller than src"
    end
    # Can't move between RAX and DIL for example.
    # TODO(david942j): rex mode
    # if dest.rex_mode & src.rex_mode == 0:
    #    log.error('The amd64 instruction set does not support moving from %s to %s' % (src, dest))

    # Downgrade our register choice if possible.
    # Opcodes for operating on 32-bit registers are always (?) shorter.
    dest = get_register(dest.native32) if dest.size == 64 && src.size <= 32
  else
    context.local(arch: 'amd64') { src = evaluate(src) }
    raise ArgumentError, format('cannot mov %s, %d: dest is smaller than src', dest, src) unless dest.fits(src)
    dest = get_register(dest.native32) if dest.size == 64 && bits_required(src) <= 32

    # Calculate the packed version
    srcp = pack(src & ((1 << dest.size) - 1), bits: dest.size)

    # Calculate the unsigned and signed versions
    srcu = unpack(srcp, bits: dest.size, signed: false)
    srcs = unpack(srcp, bits: dest.size, signed: true)
  end
  if register?(src)
    if src == dest
      cat "/* moving #{src} into #{dest}, but this is a no-op */"
    elsif dest.bigger.include?(src.name)
      cat "/* moving #{src} into #{dest}, but this is a no-op */"
    elsif dest.size > src.size
      cat "movzx #{dest}, #{src}"
    else
      cat "mov #{dest}, #{src}"
    end
  elsif src.is_a?(Numeric) # Constant or immi
    # Special case for zeroes
    # XORing the 32-bit register clears the high 32 bits as well
    if src == 0
      cat "xor #{dest}, #{dest} /* #{src} */"
    elsif stack_allowed && [32, 64].include?(dest.size) && src == 10
      cat "push 9 /* mov #{dest}, '\\n' */"
      cat "pop #{dest.native64}"
      cat "inc #{dest}"
    # It's smaller to PUSH and POP small sign-extended values
    # than to directly move them into various registers,
    #
    # 6aff58           push -1; pop rax
    # 48c7c0ffffffff   mov rax, -1
    elsif stack_allowed && [32, 64].include?(dest.size) && (-2**7 <= srcs && srcs < 2**7) && okay(srcp[0, 1])
      cat "push #{pretty(src)}"
      cat "pop #{dest.native64}"
    # Easy case, everybody is trivially happy
    # This implies that the register size and value are the same.
    elsif okay(srcp)
      cat "mov #{dest}, #{pretty(src)}"
    # We can push 32-bit values onto the stack and they are sign-extended.
    elsif stack_allowed && [32, 64].include?(dest.size) && (-2**31 <= srcs && srcs < 2**31) && okay(srcp[0, 4])
      cat "push #{pretty(src)}"
      cat "pop #{dest.native64}"
    # We can also leverage the sign-extension to our advantage.
    # For example, 0xdeadbeef is sign-extended to 0xffffffffdeadbeef.
    # Want EAX=0xdeadbeef, we don't care that RAX=0xfff...deadbeef.
    elsif stack_allowed && dest.size == 32 && srcu < 2**32 && okay(srcp[0, 4])
      cat "push #{pretty(src)}"
      cat "pop #{dest.native64}"
    # Target value is an 8-bit value, use a 8-bit mov
    elsif srcu < 2**8 && okay(srcp[0, 1]) && dest.sizes.include?(8)
      cat "xor #{dest.xor}, #{dest.xor}"
      cat "mov #{dest.sizes[8]}, #{pretty(src)}"
    # Target value is a 16-bit value with no data in the low 8 bits
    # means we can use the 'AH' style register.
    elsif srcu == srcu & 0xff00 && okay(srcp[1]) && dest.ff00
      cat "xor #{dest}, #{dest}"
      cat "mov #{dest.ff00}, #{pretty(src)} >> 8"
    # Target value is a 16-bit value, use a 16-bit mov
    elsif srcu < 2**16 && okay(srcp[0, 2])
      cat "xor #{dest.xor}, #{dest.xor}"
      cat "mov #{dest.sizes[16]}, #{pretty(src)}"
    # Target value is a 32-bit value, use a 32-bit mov.
    # Note that this is zero-extended rather than sign-extended (the 32-bit push above).
    elsif srcu < 2**32 && okay(srcp[0, 4])
      cat "mov #{dest.sizes[32]}, #{pretty(src)}"
    # All else has failed.  Use some XOR magic to move things around.
    else
      a, b = xor_pair(srcp, avoid: "\x00\n")
      a = hex(unpack(a, bits: dest.size))
      b = hex(unpack(b, bits: dest.size))
      # There's no XOR REG, IMM64 but we can take the easy route
      # for smaller registers.
      if dest.size != 64
        cat "mov #{dest}, #{a} /* #{src} == #{hex(src)} */"
        cat "xor #{dest}, #{b}"
      # However, we can PUSH IMM64 and then perform the XOR that
      # way at the top of the stack.
      elsif stack_allowed
        cat "mov #{dest}, #{a} /* #{src} == #{hex(src)} */"
        cat "push #{dest}"
        cat "mov #{dest}, #{b}"
        cat "xor [rsp], #{dest}"
        cat "pop #{dest}"
      else
        raise ArgumentError, "Cannot put #{pretty(src)} into '#{dest}' without using stack."
      end
    end
  else
    raise ArgumentError, "#{src} is neither a register nor an immediate."
  end
end
