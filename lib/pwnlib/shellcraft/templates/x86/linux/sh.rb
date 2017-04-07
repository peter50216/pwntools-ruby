# encoding: ASCII-8BIT

# Get shell!
#
# @param [Boolean, Array<String>] argv
#   Arguments of +argv+ when calling +execve+.
#   If +true+ is given, use +['sh']+.
#   If +Array<String>+ is given, use this as arguments array.
#
# @note Null pointer is always used as +envp+.
#
# @diff
#   By default, this method calls +execve('/bin///sh', 0, 0)+, which is different from python-pwntools:
#   +execve('/bin///sh', ['sh'], 0)+.
::Pwnlib::Shellcraft.define(__FILE__) do |argv: false|
  argv = case argv
         when true then ['sh']
         when false then 0
         else argv
         end
  cat shellcraft.x86.linux.syscalls.execve('/bin///sh', argv, 0)
end
