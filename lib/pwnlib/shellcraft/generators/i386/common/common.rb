require 'pwnlib/shellcraft/generators/helper'
require 'pwnlib/shellcraft/registers'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/packing'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        # For non os-related methods.
        module Common
          extend ::Pwnlib::Shellcraft::Registers
          extend ::Pwnlib::Util::Fiddling
          extend ::Pwnlib::Util::Packing

          # There's method hook in Helper module, so extend in the last line.
          extend ::Pwnlib::Shellcraft::Generators::Helper
        end
      end
    end
  end
end
