require 'pwnlib/util/fiddling'
require 'pwnlib/util/lists'
require 'pwnlib/util/packing'

# Push a string to stack
::Pwnlib::Shellcraft.define(__FILE__) do |str, append_null: true|
  extend ::Pwnlib::Util::Fiddling::ClassMethods
  extend ::Pwnlib::Util::Lists::ClassMethods
  extend ::Pwnlib::Util::Packing::ClassMethods
  # This will not effect callee's +str+.
  str += "\x00" if append_null && !str.end_with?("\x00")
  next if str.empty?
  padding = str[-1].ord >= 128 ? "\xff" : "\x00"
  cat "/* push #{str.inspect} */"
  group(8, str, underfull_action: :fill, fill_value: padding).reverse.each do |word|
    sign = u64(word, endian: 'little', signed: true)
    sign32 = u32(word[0, 4], bits: 32, endian: 'little', signed: true)
    # simple forbidden byte case
    if [0, 0xa].include?(sign)
      cat "push #{pretty(sign + 1)}"
      cat 'dec byte ptr [rsp]'
    # simple byte case
    elsif sign >= -0x80 && sign <= 0x7f
      cat "push #{pretty(sign)}"
    # simple 32bit without forbidden byte
    elsif sign >= -0x80000000 && sign <= 0x7fffffff && okay(word[0, 4])
      cat "push #{pretty(sign)}"
    elsif okay(word)
      cat "mov rax, #{pretty(sign)}"
      cat 'push rax'
    # The high 4 byte of word are all zeros, so we can use +xor dword ptr [rsp]+.
    elsif sign32 == sign
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
