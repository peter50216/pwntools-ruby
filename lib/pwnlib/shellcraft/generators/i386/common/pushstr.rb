# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/i386/common/common'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        module Common
          # Push a string to stack
          def pushstr(str, append_null: true)
            # This will not affect callee's +str+.
            str += "\x00" if append_null && !str.end_with?("\x00")
            return if str.empty?
            padding = str[-1].ord >= 128 ? "\xff" : "\x00"
            cat "/* push #{str.inspect} */"
            group(4, str, underfull_action: :fill, fill_value: padding).reverse_each do |word|
              sign = u32(word, endian: 'little', signed: true)
              if [0, 0xa].include?(sign) # simple forbidden byte case
                cat "push #{pretty(sign + 1)}"
                cat 'dec byte ptr [esp]'
              elsif sign >= -128 && sign <= 127
                cat "push #{pretty(sign)}"
              elsif okay(word)
                cat "push #{pretty(sign)}"
              else
                a = u32(xor_pair(word).first, endian: 'little', signed: false)
                cat "push #{pretty(a)}"
                cat "xor dword ptr [esp], #{pretty(a)} ^ #{pretty(sign)}"
              end
            end
          end
        end
      end
    end
  end
end
