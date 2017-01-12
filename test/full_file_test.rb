# encoding: ASCII-8BIT

require 'open3'

require 'test_helper'

class FullFileTest < MiniTest::Test
  parallelize_me!
  Dir['test/files/*.rb'].each do |f|
    fn = File.basename(f, '.rb')
    define_method("test_#{fn}") do
      _, stderr, status = Open3.capture3('ruby', f, binmode: true)
      assert(status.success?, stderr)
    end
  end
end
