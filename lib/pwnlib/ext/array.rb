# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/ext/helper'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/packing'

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
