# encoding: ASCII-8BIT
require 'pwnlib/util/packing'
require 'pwnlib/ext/helper'

module Pwnlib
  module Ext
    module Integer
      # Methods to be mixed into Integer.
      module InstanceMethods
        extend Pwnlib::Ext::Helper

        def_proxy_method Pwnlib::Util::Packing, %w(pack p8 p16 p32 p64)
        def_proxy_method Pwnlib::Util::Fiddling, %w(bits bits_str), bitswap: 'bitswap_int'
        def_proxy_method Pwnlib::Util::Fiddling, %w(hex)
      end
    end
  end
end

::Integer.send(:include, Pwnlib::Ext::Integer::InstanceMethods)
