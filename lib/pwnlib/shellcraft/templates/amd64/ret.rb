def ret(return_value = nil)
  cat amd64.mov('rax', return_value) unless return_value.nil?
  cat 'ret'
end
