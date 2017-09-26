# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          module_function
          # Move src into dest without newlines and null bytes.
          def mov(dest, src, stack_allowed: true)

            raise ArgumentError, "#{dest} is not a register" unless register?(dest)
            dest = get_register(dest)
            if register?(src)
              src = get_register(src)
              if dest.size < src.size && !dest.bigger.include?(src.name)
                raise ArgumentError, "cannot mov #{dest}, #{src}: dest is smaller than src"
              end
              # Downgrade our register choice if possible.
              # Opcodes for operating on 32-bit registers are always (?) shorter.
              dest = get_register(dest.native32) if dest.size == 64 && src.size <= 32
            else
              context.local(arch: 'amd64') { src = evaluate(src) }
              raise ArgumentError, format('cannot mov %s, %d: dest is smaller than src', dest, src) unless dest.fits(src)
              orig_dest = dest
              dest = get_register(dest.native32) if dest.size == 64 && bits_required(src) <= 32

              # Calculate the packed version.
              srcp = pack(src & ((1 << dest.size) - 1), bits: dest.size)

              # Calculate the unsigned and signed versions.
              srcu = unpack(srcp, bits: dest.size, signed: false)
              # N.B.: We may have downsized the register for e.g. mov('rax', 0xffffffff)
              #       In this case, srcp is now a 4-byte packed value, which will expand to "-1", which isn't correct.
              srcs = orig_dest.size == dest.size ? unpack(srcp, bits: dest.size, signed: true) : src
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
              if src.zero?
                # Special case for zeroes.
                # XORing the 32-bit register clears the high 32 bits as well.
                cat "xor #{dest}, #{dest} /* #{src} */"
              elsif stack_allowed && [32, 64].include?(dest.size) && src == 10
                cat "push 9 /* mov #{dest}, '\\n' */"
                cat "pop #{dest.native64}"
                cat "inc #{dest}"
              elsif stack_allowed && [32, 64].include?(dest.size) && (-2**7 <= srcs && srcs < 2**7) && okay(srcp[0])
                # It's smaller to PUSH and POP small sign-extended values than to directly move them into various registers.
                #
                # 6aff58           push -1; pop rax
                # 48c7c0ffffffff   mov rax, -1
                cat "push #{pretty(src)}"
                cat "pop #{dest.native64}"
              elsif okay(srcp)
                # Easy case. This implies that the register size and value are the same.
                cat "mov #{dest}, #{pretty(src)}"
              elsif srcu < 2**8 && okay(srcp[0]) && dest.sizes.include?(8) # Move 8-bit value into register.
                cat xor[dest]
                cat "mov #{dest.sizes[8]}, #{pretty(src)}"
              elsif srcu == srcu & 0xff00 && okay(srcp[1]) && dest.ff00
                # Target value is a 16-bit value with no data in the low 8 bits means we can use the 'AH' style register.
                cat xor[dest]
                cat "mov #{dest.ff00}, #{pretty(src)} >> 8"
              elsif srcu < 2**16 && okay(srcp[0, 2]) # Target value is a 16-bit value, use a 16-bit mov.
                cat xor[dest]
                cat "mov #{dest.sizes[16]}, #{pretty(src)}"
              else # All else has failed.  Use some XOR magic to move things around.
                a, b = xor_pair(srcp, avoid: "\x00\n")
                a = hex(unpack(a, bits: dest.size))
                b = hex(unpack(b, bits: dest.size))
                if dest.size != 64
                  # There's no XOR REG, IMM64 but we can take the easy route for smaller registers.
                  cat "mov #{dest}, #{a}"
                  cat "xor #{dest}, #{b} /* #{hex(src)} == #{a} ^ #{b} */"
                elsif stack_allowed
                  # However, we can PUSH IMM64 and then perform the XOR that way at the top of the stack.
                  cat "mov #{dest}, #{a}"
                  cat "push #{dest}"
                  cat "mov #{dest}, #{b}"
                  cat "xor [rsp], #{dest} /* #{hex(src)} == #{a} ^ #{b} */"
                  cat "pop #{dest}"
                else
                  raise ArgumentError, "Cannot put #{pretty(src)} into '#{dest}' without using stack."
                end
              end
            end
          end
        end
      end
    end
  end
end
