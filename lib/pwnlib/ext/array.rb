# encoding: ASCII-8BIT
require 'pwnlib/util/packing'
require 'pwnlib/util/fiddling'
require 'pwnlib/ext/helper'

module Pwnlib
  module Ext
    module Array
      # Methods to be mixed into Array.
      module InstanceMethods
        extend ::Pwnlib::Ext::Helper

        def_proxy_method ::Pwnlib::Util::Packing, %w(flat)
        def_proxy_method ::Pwnlib::Util::Fiddling, %w(unbits)
      end
    end
  end
end

::Array.public_send(:include, ::Pwnlib::Ext::Array::InstanceMethods)
