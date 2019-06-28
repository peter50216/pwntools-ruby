# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/logger'

module Pwnlib
  # This module collects utilities that need user interactions.
  module UI
    module_function

    # Waits for user input.
    #
    # @return [void]
    def pause
      log.info('Paused (press enter to continue)')
      $stdin.gets
    end

    include ::Pwnlib::Logger
  end
end
