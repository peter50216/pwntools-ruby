require 'pwnlib/context'

module Kernel
  private
  def context
    Pwnlib::Context.context
  end
end
