# encoding: ASCII-8BIT

require 'pwnlib/context'

module Pwnlib
  # Encapsulates information about a calling convention.
  module ABI
    # A super class for recording registers and stack's information.
    class ABI
      attr_reader :register_arguments
      def initialize(regs, align, minimum)
        @register_arguments = regs
        @arg_alignment = align
        @stack_minimum = minimum
      end

      def returns
        true
      end

      def self.default
        {
          [32, 'i386', 'linux'] => LINUX_I386,
          [64, 'amd64', 'linux'] => LINUX_AMD64,
          [32, 'arm', 'linux'] => LINUX_ARM,
          [32, 'thumb', 'linux'] => LINUX_ARM,
          [32, 'mips', 'linux'] => LINUX_MIPS,
          [32, 'i386', 'windows'] => WINDOWS_I386,
          [64, 'amd64', 'windows'] => WINDOWS_AMD64
        }[[context.bits, context.arch, context.os]]
      end

      def self.syscall
        {
          [32, 'i386', 'linux'] => LINUX_I386_SYSCALL,
          [64, 'amd64', 'linux'] => LINUX_AMD64_SYSCALL,
          [32, 'arm', 'linux'] => LINUX_ARM_SYSCALL,
          [32, 'thumb', 'linux'] => LINUX_ARM_SYSCALL,
          [32, 'mips', 'linux'] => LINUX_MIPS_SYSCALL
        }[[context.bits, context.arch, context.os]]
      end

      def self.sigreturn
        {
          [32, 'i386', 'linux'] => LINUX_I386_SIGRETURN,
          [64, 'amd64', 'linux'] => LINUX_AMD64_SIGRETURN,
          [32, 'arm', 'linux'] => LINUX_ARM_SIGRETURN,
          [32, 'thumb', 'linux'] => LINUX_ARM_SIGRETURN
        }[[context.bits, context.arch, context.os]]
      end
      extend ::Pwnlib::Context
    end

    # The syscall ABI treats the syscall number as the zeroth argument,
    # which must be loaded into the specified register.
    class SyscallABI < ABI
      def initialize(regs, align, minimum)
        super
        @syscall_register = regs[0]
      end
    end

    # The sigreturn ABI is similar to the syscall ABI, except that
    # both PC and SP are loaded from the stack.  Because of this, there
    # is no 'return' slot necessary on the stack.
    class SigreturnABI < SyscallABI
      def returns
        false
      end
    end
    LINUX_I386 = ABI.new([], 4, 0)
    LINUX_AMD64 = ABI.new(%w(rdi rsi rdx rcx r8 r9), 8, 0)
    LINUX_ARM = ABI.new(%w(r0 r1 r2 r3), 8, 0)
    LINUX_AARCH64 = ABI.new(%w(x0 x1 x2 x3), 16, 0)
    LINUX_MIPS = ABI.new(%w($a0 $a1 $a2 $a3), 4, 0)

    LINUX_I386_SYSCALL = SyscallABI.new(%w(eax ebx ecx edx esi edi ebp), 4, 0)
    LINUX_AMD64_SYSCALL = SyscallABI.new(%w(rax rdi rsi rdx r10 r8 r9), 8, 0)
    LINUX_ARM_SYSCALL = SyscallABI.new(%w(r7 r0 r1 r2 r3 r4 r5 r6), 4, 0)
    LINUX_AARCH64_SYSCALL = SyscallABI.new(%w(x8 x0 x1 x2 x3 x4 x5 x6), 16, 0)
    # Bug in python-pwntools abi.py, should be SyscallABI
    # linux_mips_syscall = ABI(['$v0', '$a0','$a1','$a2','$a3'], 4, 0)
    LINUX_MIPS_SYSCALL = SyscallABI.new(%w($v0 $a0 $a1 $a2 $a3), 4, 0)

    LINUX_I386_SIGRETURN = SigreturnABI.new(['eax'], 4, 0)
    LINUX_AMD64_SIGRETURN = SigreturnABI.new(['rax'], 4, 0)
    LINUX_ARM_SIGRETURN = SigreturnABI.new(['r7'], 4, 0)

    WINDOWS_I386 = ABI.new([], 4, 0)
    WINDOWS_AMD64 = ABI.new(%w(rcx rdx r8 r9), 32, 32)

    # Fake ABIs used by SROP
    LINUX_I386_SROP = ABI.new(['eax'], 4, 0)
    LINUX_AMD64_SROP = ABI.new(['rax'], 4, 0)
    LINUX_ARM_SROP = ABI.new(['r7'], 4, 0)
  end
end
