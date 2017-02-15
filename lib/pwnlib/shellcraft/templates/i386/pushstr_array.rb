require 'pwnlib/shellcraft/shellcraft'

# Pushes an array of pointers onto the stack.
#
# @param [String] reg
#   Destination register to hold the result pointer.
# @param [Array<String>] array
#   Single list of arguments to push. NULL termination is
#   normalized so that each argument ends with exactly one NULL byte.
::Pwnlib::Shellcraft.define(__FILE__) do |reg, array|
  i386 = ::Pwnlib::Shellcraft.instance.i386
  array = array.map { |a| a.gsub(/\x00+\Z/, '') + "\x00" }
  array_str = array.join
  word_size = 4
  offset = array_str.size + word_size
  cat "/* push argument array #{array.inspect} */"
  cat i386.pushstr(array_str)
  cat i386.mov(reg, 0)
  cat "push #{reg} /* null terminate */"
  array.reverse.each_with_index do |arg, i|
    cat i386.mov(reg, offset + word_size * i - arg.size)
    cat "add #{reg}, esp"
    cat "push #{reg} /* #{arg.inspect} */"
    offset -= arg.size
  end
  cat i386.mov(reg, 'esp')
end
