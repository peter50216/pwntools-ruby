# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # Move +src+ into +dst+ without newlines and null bytes.
          #
          # @param [String, Symbol] dst
          #   Register name.
          # @param [String, Symbol, Integer] src
          #   Register name or immediate value.
          # @param [Boolean] stack_allowed
          #   If equals to +false+, generated assembly code would not use stack-related operations.
          #   But beware of without stack-related operations the generated code length is longer.
          #
          # @example
          #   mov('rdi', 'ax')
          #   #=> "  movzx edi, ax\n"
          # @example
          #   puts mov('rax', 10)
          #   #   push 9 /* mov eax, '\n' */
          #   #   pop rax
          #   #   inc eax
          #   #=> nil
          # @example
          #   puts mov('rax', 10, stack_allowed: false)
          #   #   mov eax, 0x1010101
          #   #   xor eax, 0x101010b /* 0xa == 0x1010101 ^ 0x101010b */
          #   #=> nil
          def mov(dst, src, stack_allowed: true)
            raise ArgumentError, "#{dst} is not a register" unless register?(dst)
            dst = get_register(dst)
            if register?(src)
              src = get_register(src)
              if dst.size < src.size && !dst.bigger.include?(src.name)
                raise ArgumentError, "cannot mov #{dst}, #{src}: dst is smaller than src"
              end
              # Downgrade our register choice if possible.
              # Opcodes for operating on 32-bit registers are always (?) shorter.
              dst = get_register(dst.native32) if dst.size == 64 && src.size <= 32
            else
              context.local(arch: 'amd64') { src = evaluate(src) }
              raise ArgumentError, format('cannot mov %s, %d: dst is smaller than src', dst, src) unless dst.fits(src)
              orig_dst = dst
              dst = get_register(dst.native32) if dst.size == 64 && bits_required(src) <= 32

              # Calculate the packed version.
              srcp = pack(src & ((1 << dst.size) - 1), bits: dst.size)

              # Calculate the unsigned and signed versions.
              srcu = unpack(srcp, bits: dst.size, signed: false)
              # N.B.: We may have downsized the register for e.g. mov('rax', 0xffffffff)
              #       In this case, srcp is now a 4-byte packed value, which will expand to "-1", which isn't correct.
              srcs = orig_dst.size == dst.size ? unpack(srcp, bits: dst.size, signed: true) : src
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
              if src.zero?
                # Special case for zeroes.
                # XORing the 32-bit register clears the high 32 bits as well.
                cat "xor #{dst}, #{dst} /* #{src} */"
              elsif stack_allowed && [32, 64].include?(dst.size) && src == 10
                cat "push 9 /* mov #{dst}, '\\n' */"
                cat "pop #{dst.native64}"
                cat "inc #{dst}"
              elsif stack_allowed && [32, 64].include?(dst.size) && (-2**7 <= srcs && srcs < 2**7) && okay(srcp[0])
                # It's smaller to PUSH and POP small sign-extended values than to directly move them into various
                # registers.
                #
                # 6aff58           push -1; pop rax
                # 48c7c0ffffffff   mov rax, -1
                cat "push #{pretty(src)}"
                cat "pop #{dst.native64}"
              elsif okay(srcp)
                # Easy case. This implies that the register size and value are the same.
                cat "mov #{dst}, #{pretty(src)}"
              elsif srcu < 2**8 && okay(srcp[0]) && dst.sizes.include?(8) # Move 8-bit value into register.
                cat xor[dst]
                cat "mov #{dst.sizes[8]}, #{pretty(src)}"
              elsif srcu == srcu & 0xff00 && okay(srcp[1]) && dst.ff00
                # Target value is a 16-bit value with no data in the low 8 bits, we can use the 'AH' style register.
                cat xor[dst]
                cat "mov #{dst.ff00}, #{pretty(src)} >> 8"
              elsif srcu < 2**16 && okay(srcp[0, 2]) # Target value is a 16-bit value, use a 16-bit mov.
                cat xor[dst]
                cat "mov #{dst.sizes[16]}, #{pretty(src)}"
              else # All else has failed.  Use some XOR magic to move things around.
                a, b = xor_pair(srcp, avoid: "\x00\n")
                a = hex(unpack(a, bits: dst.size))
                b = hex(unpack(b, bits: dst.size))
                if dst.size != 64
                  # There's no XOR REG, IMM64 but we can take the easy route for smaller registers.
                  cat "mov #{dst}, #{a}"
                  cat "xor #{dst}, #{b} /* #{hex(src)} == #{a} ^ #{b} */"
                elsif stack_allowed
                  # However, we can PUSH IMM64 and then perform the XOR that way at the top of the stack.
                  cat "mov #{dst}, #{a}"
                  cat "push #{dst}"
                  cat "mov #{dst}, #{b}"
                  cat "xor [rsp], #{dst} /* #{hex(src)} == #{a} ^ #{b} */"
                  cat "pop #{dst}"
                else
                  raise ArgumentError, "Cannot put #{pretty(src)} into '#{dst}' without using stack."
                end
              end
            end
          end
        end
      end
    end
  end
end
