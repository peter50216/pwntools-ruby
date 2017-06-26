require 'pwnlib/context'

module Pwnlib
  module Shellcraft
    # Define register names and methods for shellcode generators.
    module Registers
      X86_BASEREGS = %w(ax cx dx bx sp bp si di ip).freeze

      I386 = (X86_BASEREGS.map { |r| "e#{r}" } +
             X86_BASEREGS +
             %w(eflags cs ss ds es fs gs)).freeze

      AMD64 = (X86_BASEREGS.map { |r| "r#{r}" } +
               (8..15).map { |r| "r#{r}" } +
               (8..15).map { |r| "r#{r}d" } +
               I386).freeze

      # x86 registers in decreasing size
      X86_ORDERED = ([
        %w(rax eax ax al),
        %w(rbx ebx bx bl),
        %w(rcx ecx cx cl),
        %w(rdx edx dx dl),
        %w(rdi edi di),
        %w(rsi esi si),
        %w(rbp ebp bp),
        %w(rsp esp sp)
      ] + (8..15).map { |r| ['', 'd', 'w', 'b'].map { |t| "r#{r}#{t}" } }).freeze

      # class Register, currently only supports i386 and amd64.
      class Register
        # @return [String]
        #   Register's name.
        attr_reader :name
        attr_reader :bigger, :smaller, :ff00, :is64bit, :native64, :native32, :xor
        attr_reader :size, :sizes

        # Instantiate a {Register} object.
        #
        # Create a register by its name and size (in bits) for fetching other information. For example, for register
        # 'ax', +#bigger+ contains 'rax' and 'eax'.
        #
        # Normally you don't need to create any {Register} object, use {.get_register} to get register by name.
        #
        # @param [String] name
        #   Register's name.
        # @param [Integer] size
        #   Register size in bits.
        #
        # @example
        #   Register.new('rax', 64)
        #   Register.new('bx', 16)
        def initialize(name, size)
          @name = name
          @size = size
          X86_ORDERED.each do |row|
            next unless row.include?(name)
            @bigger = row[0, row.index(name)]
            @smaller = row[(row.index(name) + 1)..-1]
            @native64 = row[0]
            @native32 = row[1]
            @sizes = row.each_with_object({}).with_index { |(r, h), i| h[64 >> i] = r }
            @xor = @sizes[[size, 32].min]
            break
          end
          @ff00 = name[1] + 'h' if @size >= 32 && @name.end_with?('x')
          @is64bit = true if @name.start_with?('r')
        end

        def bits
          size
        end

        def bytes
          bits / 8
        end

        def fits(value)
          size >= Registers.bits_required(value)
        end

        def to_s
          name
        end

        def inspect
          format('Register(%s)', name)
        end
      end

      module_function

      def registers
        {
          [32, 'i386', 'linux'] => ::Pwnlib::Shellcraft::Registers::I386,
          [64, 'amd64', 'linux'] => ::Pwnlib::Shellcraft::Registers::AMD64
        }[[context.bits, context.arch, context.os]]
      end

      INTEL = (X86_ORDERED.each_with_object({}) do |row, obj|
        row.each_with_index do |reg, i|
          obj[reg] = Register.new(reg, 64 >> i)
        end
      end).freeze

      # Get a {Register} object by name.
      #
      # @param [String, Register] name
      #   The name of register.
      #   If +name+ is already a {Register} object, +name+ itself will be returned.
      #
      # @return [Register, nil]
      #   Get the register with name +name+.
      #
      # @example
      #   Registers.get_register('eax')
      #   #=> Register(eax)
      #   Registers.get_register('xdd')
      #   #=> nil
      def get_register(name)
        return name if name.instance_of?(Register)
        return INTEL[name] if name.instance_of?(String)
        nil
      end

      def register?(obj)
        !get_register(obj).nil?
      end

      def bits_required(value)
        bits = 0
        value = value.abs
        while value > 0
          bits += 8
          value >>= 8
        end
        bits
      end

      include ::Pwnlib::Context
    end
  end
end
