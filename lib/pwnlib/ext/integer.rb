# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/ext/helper'
require 'pwnlib/util/packing'

module Pwnlib
  module Ext
    module Integer
      # Methods to be mixed into Integer.
      module InstanceMethods
        extend ::Pwnlib::Ext::Helper

        def_proxy_method ::Pwnlib::Util::Packing, %w(pack p8 p16 p32 p64)
        def_proxy_method ::Pwnlib::Util::Fiddling, %w(bits bits_str), bitswap: 'bitswap_int'
        def_proxy_method ::Pwnlib::Util::Fiddling, %w(hex)
      end
    end
  end
end

::Integer.public_send(:include, ::Pwnlib::Ext::Integer::InstanceMethods)
