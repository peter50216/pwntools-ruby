# encoding: ASCII-8BIT

# Make sure we're using local copy for local testing.
$LOAD_PATH.unshift File.expand_path(File.join(__FILE__, '..', '..', '..', 'lib'))

# TODO(Darkpi): Should we make sure ALL module works? (maybe we should).
require 'pwnlib/util/packing'

raise 'call from module fail' unless ::Pwnlib::Util::Packing.p8(0x61) == 'a'

include ::Pwnlib::Util::Packing::ClassMethod
raise 'include module and call fail' unless p8(0x61) == 'a'

begin
  ::Pwnlib::Util::Packing.context
  raise 'context public in Pwnlib module'
rescue NoMethodError
  puts 'good'
end
