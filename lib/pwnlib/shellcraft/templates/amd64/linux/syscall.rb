require 'pwnlib/abi'
require 'pwnlib/constants/constant'
require 'pwnlib/shellcraft/shellcraft'

# Assembly of `syscall`.
Pwnlib::Shellcraft.define('amd64.linux.syscall') do |*arguments|
  abi = ::Pwnlib::ABI::LINUX_AMD64_SYSCALL
  amd64 = ::Pwnlib::Shellcraft.instance.amd64
  syscall, arg0, arg1, arg2, arg3, arg4, arg5 = arguments
  if (syscall.is_a?(String) || syscall.is_a?(::Pwnlib::Constants::Constant)) && syscall.to_s.start_with?('SYS_')
    syscall_repr = syscall.to_s[4..-1] + '(%s)'
    args = []
  else
    syscall_repr = 'syscall(%s)'
    args = syscall.nil? ? ['?'] : [syscall.inspect]
  end
  # arg0 to arg5
  1.upto(6) do |i|
    args.push(arguments[i].nil? ? '?' : arguments[i].inspect)
  end

  args.pop while args.last == '?'
  syscall_repr = format(syscall_repr, args.join(', '))
  registers = abi.register_arguments
  arguments = [syscall, arg0, arg1, arg2, arg3, arg4, arg5]
  reg_ctx   = registers.zip(arguments).to_h
  cat "/* call #{syscall_repr} */"
  cat amd64.setregs(reg_ctx) if arguments.any? { |v| !v.nil? }
  cat 'syscall'
end
