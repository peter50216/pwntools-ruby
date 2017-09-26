require 'pwnlib/shellcraft/generators/helper'

module Pwnlib
  module Shellcraft
    module Generators
      module I386
        # For os-related methods.
        module Linux
          # There's method hook in Helper module, so extend in the last line.
          extend ::Pwnlib::Shellcraft::Generators::Helper
        end
      end
    end
  end
end
