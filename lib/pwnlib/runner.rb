# encoding: ASCII-8BIT

require 'fileutils'

require 'pwnlib/asm'
require 'pwnlib/tubes/process'

module Pwnlib
  # Create a tube from data.
  module Runner
    module_function

    # Given an assembly listing, assemble and execute it.
    #
    # @param [String] assembly
    #   Assembly code.
    #
    # @return [Pwnlib::Tubes::Process]
    #   The tube for interacting.
    #
    # @see Runner.run_shellcode
    def run_assembly(assembly)
      run_shellcode(::Pwnlib::Asm.asm(assembly))
    end

    # Given assembled machine code bytes, execute them.
    #
    # @param [String] bytes
    #   Assembled code
    #
    # @return [Pwnlib::Tubes::Process]
    #   The tube for interacting.
    #
    # @example
    #   r = run_shellcode(asm(shellcraft.cat('/etc/passwd')))
    #   r.interact
    #   # [INFO] Switching to interactive mode
    #   # root:x:0:0:root:/root:/bin/bash
    #   # daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
    #   # bin:x:2:2:bin:/bin:/usr/sbin/nologin
    #   # sys:x:3:3:sys:/dev:/usr/sbin/nologin
    #   # sync:x:4:65534:sync:/bin:/bin/sync
    #   # games:x:5:60:games:/usr/games:/usr/sbin/nologin
    #   # [INFO] Got EOF in interactive mode
    #   #=> true
    def run_shellcode(bytes)
      file = ::Pwnlib::Asm.make_elf(bytes, to_file: true)
      at_exit { FileUtils.rm_f(file) if File.exist?(file) }
      ::Pwnlib::Tubes::Process.new(file)
    end
  end
end
