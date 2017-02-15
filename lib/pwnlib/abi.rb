# encoding: ASCII-8BIT

require 'pwnlib/context'

module Pwnlib
  # Encapsulates information about a calling convention.
  module ABI
    # A super class for recording registers and stack's information.
    class ABI
      attr_reader :register_arguments
      # Only use for x86, to specific the +eax+, +edx+ pair.
      attr_reader :cdq_pair
      def initialize(regs, align, minimum, cdq_pair: nil)
        @register_arguments = regs
        @arg_alignment = align
        @stack_minimum = minimum
        @cdq_pair = cdq_pair
      end

      def returns
        true
      end

      def self.default
        {
          [32, 'i386', 'linux'] => LINUX_I386,
          [64, 'amd64', 'linux'] => LINUX_AMD64
        }[[context.bits, context.arch, context.os]]
      end

      def self.syscall
        {
          [32, 'i386', 'linux'] => LINUX_I386_SYSCALL,
          [64, 'amd64', 'linux'] => LINUX_AMD64_SYSCALL
        }[[context.bits, context.arch, context.os]]
      end
      extend ::Pwnlib::Context
    end

    # The syscall ABI treats the syscall number as the zeroth argument,
    # which must be loaded into the specified register.
    class SyscallABI < ABI
      attr_reader :syscall_str
      attr_reader :stack_register
      def initialize(regs, align, minimum, syscall_str, stack_register)
        super(regs, align, minimum)
        @syscall_str = syscall_str
        @stack_register = stack_register
      end
    end

    LINUX_I386 = ABI.new([], 4, 0, cdq_pair: %w(eax edx))
    LINUX_AMD64 = ABI.new(%w(rdi rsi rdx rcx r8 r9), 8, 0, cdq_pair: %w(rax rdx))

    LINUX_I386_SYSCALL = SyscallABI.new(%w(eax ebx ecx edx esi edi ebp), 4, 0, 'int 0x80', 'esp')
    LINUX_AMD64_SYSCALL = SyscallABI.new(%w(rax rdi rsi rdx r10 r8 r9), 8, 0, 'syscall', 'rsp')
  end
end
