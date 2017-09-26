# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/amd64/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        module Common
          # Push a string to stack.
          def pushstr(str, append_null: true)
            # This will not affect callee's +str+.
            str += "\x00" if append_null && !str.end_with?("\x00")
            return if str.empty?
            padding = str[-1].ord >= 128 ? "\xff" : "\x00"
            cat "/* push #{str.inspect} */"
            group(8, str, underfull_action: :fill, fill_value: padding).reverse_each do |word|
              sign = u64(word, endian: 'little', signed: true)
              sign32 = u32(word[0, 4], bits: 32, endian: 'little', signed: true)
              if [0, 0xa].include?(sign) # simple forbidden byte case
                cat "push #{pretty(sign + 1)}"
                cat 'dec byte ptr [rsp]'
              elsif sign >= -0x80 && sign <= 0x7f && okay(word[0]) # simple byte case
                cat "push #{pretty(sign)}"
              elsif sign >= -0x80000000 && sign <= 0x7fffffff && okay(word[0, 4])
                # simple 32bit without forbidden byte
                cat "push #{pretty(sign)}"
              elsif okay(word)
                cat "mov rax, #{pretty(sign)}"
                cat 'push rax'
              elsif sign32 > 0 && word[4, 4] == "\x00" * 4
                # The high 4 byte of word are all zeros, so we can use +xor dword ptr [rsp]+.
                a = u32(xor_pair(word[0, 4]).first, endian: 'little', signed: true)
                cat "push #{pretty(a)} ^ #{pretty(sign)}"
                cat "xor dword ptr [rsp], #{pretty(a)}"
              else
                a = u64(xor_pair(word).first, endian: 'little', signed: false)
                cat "mov rax, #{pretty(a)}"
                cat 'push rax'
                cat "mov rax, #{pretty(a)} ^ #{pretty(sign)}"
                cat 'xor [rsp], rax'
              end
            end
          end
        end
      end
    end
  end
end
