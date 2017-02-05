::Pwnlib::Shellcraft.define(__FILE__) do
  label = get_label('infloop')
  cat "#{label}:"
  cat "jmp #{label}"
end
