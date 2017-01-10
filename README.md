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

There's almost NOTHING here now.
(Edit: there's something here now, but not much :wink:)
Going to implement important things (socket, tubes, asm/disasm, pack/unpack utilities) first.
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
