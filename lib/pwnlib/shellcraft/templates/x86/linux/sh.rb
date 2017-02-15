# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/shellcraft'

# Get shell!
#
# @param [Boolean, Array<String>] argv
#   Arguments of +argv+ when calling +execve+.
#   If +true+ is given, use +['sh']+.
#   If +Array<String>+ is given, use this as arguments array.
# @note envp will always use null-pointer.
# @diff
#   By default, this method calls +execve('/bin///sh', 0, 0)+,
#   which is different from python-pwntools: +execve('/bin///sh', ['sh'], 0)+.
::Pwnlib::Shellcraft.define(__FILE__) do |argv: false|
  argv = case argv
         when true then ['sh']
         when false then 0
         else argv
         end
  cat ::Pwnlib::Shellcraft.instance.x86.linux.syscalls.execve('/bin///sh', argv, 0)
end
