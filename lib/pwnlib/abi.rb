# encoding: ASCII-8BIT
# frozen_string_literal: true

require 'pwnlib/context'

module Pwnlib
  # Encapsulates information about a calling convention.
  module ABI
    # A super class for recording registers and stack's information.
    class ABI
      attr_reader :register_arguments, :arg_alignment, :stack_pointer
      # Only used for x86, to specify the +eax+, +edx+ pair.
      attr_reader :cdq_pair

      def initialize(regs, align, stack_pointer, cdq_pair: nil)
        @register_arguments = regs
        @arg_alignment = align
        @stack_pointer = stack_pointer
        @cdq_pair = cdq_pair
      end

      class << self
        def default
          DEFAULT[arch_key]
        end

        def syscall
          SYSCALL[arch_key]
        end

        private

        def arch_key
          [context.bits, context.arch, context.os]
        end
        include ::Pwnlib::Context
      end
    end

    # The syscall ABI treats the syscall number as the zeroth argument,
    # which must be loaded into the specified register.
    class SyscallABI < ABI
      attr_reader :syscall_str

      def initialize(regs, align, stack_pointer, syscall_str)
        super(regs, align, stack_pointer)
        @syscall_str = syscall_str
      end
    end

    DEFAULT = {
      [32, 'i386', 'linux'] => ABI.new([], 4, 'esp', cdq_pair: %w(eax edx)),
      [64, 'amd64', 'linux'] => ABI.new(%w(rdi rsi rdx rcx r8 r9), 8, 'rsp', cdq_pair: %w(rax rdx))
    }.freeze

    SYSCALL = {
      [32, 'i386', 'linux'] => SyscallABI.new(%w(eax ebx ecx edx esi edi ebp), 4, 'esp', 'int 0x80'),
      [64, 'amd64', 'linux'] => SyscallABI.new(%w(rax rdi rsi rdx r10 r8 r9), 8, 'rsp', 'syscall')
    }.freeze
  end
end
