# frozen_string_literal: true

require 'pwnlib/shellcraft/generators/helper'

module Pwnlib
  module Shellcraft
    module Generators
      module Amd64
        # For os-related methods.
        module Linux
          extend ::Pwnlib::Shellcraft::Generators::Helper
        end
      end
    end
  end
end
