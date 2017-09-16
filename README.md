[![GitHub stars](https://img.shields.io/github/stars/peter50216/pwntools-ruby.svg)](https://github.com/peter50216/pwntools-ruby/stargazers)
[![Dependency Status](https://img.shields.io/gemnasium/peter50216/pwntools-ruby.svg)](https://gemnasium.com/peter50216/pwntools-ruby)
[![Build Status](https://img.shields.io/travis/peter50216/pwntools-ruby.svg)](https://travis-ci.org/peter50216/pwntools-ruby)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/peter50216/pwntools-ruby.svg)](https://codeclimate.com/github/peter50216/pwntools-ruby/coverage)
[![Code Climate](https://img.shields.io/codeclimate/github/peter50216/pwntools-ruby.svg)](https://codeclimate.com/github/peter50216/pwntools-ruby)
[![Inline docs](https://inch-ci.org/github/peter50216/pwntools-ruby.svg)](https://inch-ci.org/github/peter50216/pwntools-ruby)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](http://choosealicense.com/licenses/mit/)

# pwntools-ruby

Always sad when playing CTF that there's nothing equivalent to pwntools in Python.
While pwntools is awesome, I always love Ruby far more than Python...
So this is an attempt to create such library.

Would try to have consistent naming with original pwntools, and do things in Ruby style.

# Example Usage
```ruby
# encoding: ASCII-8BIT
# The encoding line is important most time, or you'll get "\u0000" when using "\x00" in code,
# which is NOT what we want when doing pwn...

require 'pwn'

p pack(0x41424344)  # 'DCBA'
context.endian = 'big'
p pack(0x41424344)  # 'ABCD'

context.local(bits: 16) do
  p pack(0x4142)  # 'AB'
end

context.log_level = :debug
s = Sock.new('exploitme.example.com', 31337)
# EXPLOIT CODE GOES HERE
s.send(0xdeadbeef.p32)
s.send(asm(shellcraft.sh))
s.interact
```

More features and details can be found in TBA.

# Installation

Since there are two gems, which `pwntools-ruby` depends on, didn't be published to rubygems,
you should install them by self. :disappointed:

```sh
gem install pwntools

git clone https://github.com/bnagy/crabstone.git /tmp/crabstone
cd /tmp/crabstone
gem build crabstone.gemspec
gem install crabstone

git clone https://github.com/sashs/ruby-keystone.git /tmp/ruby-keystone
cd /tmp/ruby-keystone/keystone_gem
gem build keystone.gemspec
gem install keystone
```

Some of the features (assembling/disassembling) require non-Ruby dependencies. Checkout the
installation guide for
[keystone-engine](https://github.com/keystone-engine/keystone/tree/master/docs) and
[capstone-engine](http://www.capstone-engine.org/documentation.html).

Or you can be able to get running quickly with
```sh
# Install capstone
sudo apt-get install libcapstone3

# Compile and install Keystone from source.
sudo apt-get install cmake
git clone https://github.com/keystone-engine/keystone.git /tmp/keystone
cd /tmp/keystone
mkdir build
cd build
../make-share.sh
sudo make install
```

# Development
```sh
git clone git@github.com:peter50216/pwntools-ruby.git
cd pwntools-ruby
rake
```

# Note to irb users
irb defines `main.context`.

For the ease of exploit development in irb, that method would be removed if you use `require 'pwn'`.

You can still get the `IRB::Context` by `irb_context`.
