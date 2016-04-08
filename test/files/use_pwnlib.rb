# encoding: ASCII-8BIT
require 'pwnlib/util/packing'

raise 'call from module fail' unless Pwnlib::Util::Packing.p8(0x61) == 'a'

include Pwnlib::Util::Packing::ClassMethod
raise 'include module and call fail' unless p8(0x61) == 'a'
