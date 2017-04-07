# encoding: ASCII-8BIT

require 'pwnlib/util/fiddling'
require 'pwnlib/util/lists'
require 'pwnlib/util/packing'

# Push a string to stack
::Pwnlib::Shellcraft.define(__FILE__) do |str, append_null: true|
  extend ::Pwnlib::Util::Fiddling
  extend ::Pwnlib::Util::Lists
  extend ::Pwnlib::Util::Packing
  # This will not affect callee's +str+.
  str += "\x00" if append_null && !str.end_with?("\x00")
  next if str.empty?
  padding = str[-1].ord >= 128 ? "\xff" : "\x00"
  cat "/* push #{str.inspect} */"
  group(4, str, underfull_action: :fill, fill_value: padding).reverse_each do |word|
    sign = u32(word, endian: 'little', signed: true)
    # simple forbidden byte case
    if [0, 0xa].include?(sign)
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
