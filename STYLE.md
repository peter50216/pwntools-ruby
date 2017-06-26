# Coding style / document style guideline.

We follow [rubocop](https://github.com/bbatsov/rubocop) for most of the things.
See `.rubocop.yml` for the configuration.

Results of some discussion of styles are put here,
so we can have consistent style over the code base.

## `(a..b)` or `a.upto(b)`
```ruby
# Good
(a..b).map { ... }
(a...b).map { ... }
a.upto(b) { ... }
b.downto(a) { ... }

# Bad
(a..b).each { ... }
(a..b).reverse_each { ... }
a.upto(b).map { ... }
```

## YARD tag order
Tag order is `@param, @return, @yieldparam, @yieldreturn, @raise, @todo, @note, @diff, @example`.

No new line between tags of the same kind,
a new line between tags of different kind,
and a new line between the document string and the first tag.

## `require` order
Four groups: Ruby stdlib, other dependencies, `test_helper` (for tests), our library.

A new line between each group,
and sort alphabetically in each group.

Example for header:
```ruby
# encoding: ASCII-8BIT

require 'open3'
require 'socket'

require 'dentaku'
require 'rainbow'

require 'test_helper'

require 'pwnlib/context'
require 'pwnlib/version'
```

## Document style
* Public methods intended to be used by user should be documented.
* `@param`, `@return` document on a indented new line.
```ruby
# Good
# @param [String] bla
#   A bla argument.

# Bad
# @param [String] bla A bla argument.
```

## Comment style
```ruby
# Good
# TODO(myname): A single line todo.

# TODO(myname):
#   A multiple line and long long long looooooooooooooooooooooong todo,
#   Second line!!!!!

# Bad
# TODO(myname): A multiple line and long long long looooooooooooooooooooooong todo,
#   Second line!!!!!
```
* Use `@todo` tag if it's worthy to show the todo in document, use `# TODO` elsewhere.
