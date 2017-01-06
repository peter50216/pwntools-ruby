# encoding: ASCII-8BIT

# require this file for easy exploit development, but would pollute main Object
# and some built-in objects (String, Integer, ...)

require 'pwnlib/pwn'

require 'pwnlib/ext/string'
require 'pwnlib/ext/integer'
require 'pwnlib/ext/array'

extend Pwn

require 'pwnlib/shellcraft/shellcraft'
extend Pwnlib::Shellcraft

require 'pwnlib/constants/constants'
require 'pwnlib/reg_sort'

include Pwnlib
