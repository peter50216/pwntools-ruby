# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Common
          module_function

          # Move +src+ into +dst+ without newlines and null bytes.
          def mov(dst, src, stack_allowed: true)
            raise ArgumentError, "#{dst} is not a register" unless register?(dst)
            dst = get_register(dst)
            raise ArgumentError, "cannot use #{dst} on i386" if dst.size > 32 || dst.is64bit
            if register?(src)
              src = get_register(src)
              raise ArgumentError, "cannot use #{src} on i386" if src.size > 32 || src.is64bit
              if dst.size < src.size && !dst.bigger.include?(src.name)
                raise ArgumentError, "cannot mov #{dst}, #{src}: dst is smaller than src"
              end
            else
              context.local(arch: 'i386') { src = evaluate(src) }
              raise ArgumentError, format('cannot mov %s, %d: dst is smaller than src', dst, src) unless dst.fits(src)

              # Calculate the packed version
              srcp = pack(src & ((1 << dst.size) - 1), bits: dst.size)

              # Calculate the unsigned and signed versions
              srcu = unpack(srcp, bits: dst.size, signed: false)
              srcs = unpack(srcp, bits: dst.size, signed: true)
              srcp_neg = p32(-src)
              srcp_not = p32(src ^ 0xffffffff)
            end
            if register?(src)
              if src == dst || dst.bigger.include?(src.name)
                cat "/* moving #{src} into #{dst}, but this is a no-op */"
              elsif dst.size > src.size
                cat "movzx #{dst}, #{src}"
              else
                cat "mov #{dst}, #{src}"
              end
            elsif src.is_a?(Numeric) # Constant or immi
              xor = ->(reg) { "xor #{reg.xor}, #{reg.xor}" }
              if src.zero? # special case for zeroes
                cat "xor #{dst}, #{dst} /* #{src} */"
              elsif stack_allowed && dst.size == 32 && src == 10
                cat "push 9 /* mov #{dst}, '\\n' */"
                cat "pop #{dst}"
                cat "inc #{dst}"
              elsif stack_allowed && dst.size == 32 && (-2**7 <= srcs && srcs < 2**7) && okay(srcp[0])
                cat "push #{pretty(src)}"
                cat "pop #{dst}"
              elsif okay(srcp)
                # Easy case. This implies that the register size and value are the same.
                cat "mov #{dst}, #{pretty(src)}"
              elsif srcu < 2**8 && okay(srcp[0]) && dst.sizes.include?(8)
                # Move 8-bit value into reg.
                cat xor[dst]
                cat "mov #{dst.sizes[8]}, #{pretty(src)}"
              elsif srcu == srcu & 0xff00 && okay(srcp[1]) && dst.ff00
                # Target value is a 16-bit value with no data in the low 8 bits, we can use the 'AH' style register.
                cat xor[dst]
                cat "mov #{dst.ff00}, #{pretty(src)} >> 8"
              elsif srcu < 2**16 && okay(srcp[0, 2])
                # Target value is a 16-bit value, use a 16-bit mov.
                cat xor[dst]
                cat "mov #{dst.sizes[16]}, #{pretty(src)}"
              elsif okay(srcp_neg)
                cat "mov #{dst}, -#{pretty(src)}"
                cat "neg #{dst}"
              elsif okay(srcp_not)
                cat "mov #{dst}, (-1) ^ #{pretty(src)}"
                cat "not #{dst}"
              else
                # All else has failed.  Use some XOR magic to move things around.
                a, b = xor_pair(srcp, avoid: "\x00\n")
                a = hex(unpack(a, bits: dst.size))
                b = hex(unpack(b, bits: dst.size))
                cat "mov #{dst}, #{a}"
                cat "xor #{dst}, #{b} /* #{hex(src)} == #{a} ^ #{b} */"
              end
            end
          end
        end
      end
    end
  end
end
