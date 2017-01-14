require 'pwnlib/shellcraft/shellcraft'

# Pushes an array of pointers onto the stack.
#
# @param [String] reg
#   Destination register to hold the result pointer.
# @param [Array<String>] array
#   Single list of arguments to push. NULL termination is
#   normalized so that each argument ends with exactly one NULL byte.
::Pwnlib::Shellcraft.define('amd64.pushstr_array') do |reg, array|
  amd64 = ::Pwnlib::Shellcraft.instance.amd64
  array = array.map { |a| a.gsub(/\x00+\Z/, '') + "\x00" }
  array_str = array.join
  word_size = 8
  offset = array_str.size + word_size
  cat "/* push argument array #{array.inspect} */"
  cat amd64.pushstr(array_str)
  cat amd64.mov(reg, 0)
  cat "push #{reg} /* null terminate */"
  array.reverse.each_with_index do |arg, i|
    cat amd64.mov(reg, offset + word_size * i - arg.size)
    cat "add #{reg}, rsp"
    cat "push #{reg} /* #{arg.inspect} */"
    offset -= arg.size
  end
  cat amd64.mov(reg, 'rsp')
end
