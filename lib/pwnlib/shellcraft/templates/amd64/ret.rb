::Pwnlib::Shellcraft.define(__FILE__) do |return_value = nil|
  cat shellcraft.amd64.mov('rax', return_value) unless return_value.nil?
  cat 'ret'
end
