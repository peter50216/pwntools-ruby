# encoding: ASCII-8BIT
require 'pwnlib/util/packing'

fail unless Pwnlib::Util::Packing.p8(0x61) == 'a'

include Pwnlib::Util::Packing::ClassMethod
fail unless p8(0x61) == 'a'
