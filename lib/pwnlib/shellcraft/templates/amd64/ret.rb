require 'pwnlib/shellcraft/shellcraft'
def ret(return_value: nil)
  # TODO(david942j): should be amd64.mov
  cat mov('rax', return_value) unless return_value.nil?
  cat 'ret'
end
