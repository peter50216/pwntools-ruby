# encoding: ASCII-8BIT

require 'pwnlib/abi'

# Push an array of pointers onto the stack.
#
# @param [String] reg
#   Destination register to hold the result pointer.
# @param [Array<String>] array
#   List of arguments to push.
#   NULL termination is normalized so that each argument ends with exactly one NULL byte.
::Pwnlib::Shellcraft.define(__FILE__) do |reg, array|
  abi = ::Pwnlib::ABI::ABI.default
  array = array.map { |a| a.gsub(/\x00+\Z/, '') + "\x00" }
  array_str = array.join
  word_size = abi.arg_alignment
  offset = array_str.size + word_size
  cat "/* push argument array #{array.inspect} */"
  cat shellcraft.pushstr(array_str)
  cat shellcraft.mov(reg, 0)
  cat "push #{reg} /* null terminate */"
  array.reverse.each_with_index do |arg, i|
    cat shellcraft.mov(reg, offset + word_size * i - arg.size)
    cat "add #{reg}, #{abi.stack_pointer}"
    cat "push #{reg} /* #{arg.inspect} */"
    offset -= arg.size
  end
  cat shellcraft.mov(reg, abi.stack_pointer)
end
