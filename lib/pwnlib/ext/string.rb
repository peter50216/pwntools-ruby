# encoding: ASCII-8BIT
require 'pwnlib/util/packing'
require 'pwnlib/util/fiddling'
require 'pwnlib/ext/helper'

module Pwnlib
  module Ext
    module String
      # Methods to be mixed into String.
      module InstanceMethods
        extend Pwnlib::Ext::Helper

        define_proxy_method Pwnlib::Util::Packing, %w(unpack unpack_many u8 u16 u32 u64)
        define_proxy_method Pwnlib::Util::Fiddling, %w(
          enhex unhex urlencode urldecode bits bits_str unbits bitswap b64e b64d)
      end
    end
  end
end

::String.send(:include, Pwnlib::Ext::String::InstanceMethods)
