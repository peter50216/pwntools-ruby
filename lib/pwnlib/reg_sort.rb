# encoding: ASCII-8BIT

require 'pwnlib/context'

module Pwnlib
  # Topographical sort
  module RegSort
    # @note Do not create and call instance method here. Instead, call module method on {RegSort}.
    module ClassMethod
      # Sorts register dependencies.
      #
      # Given a dictionary of registers to desired register contents,
      # return the optimal order in which to set the registers to
      # those contents.
      #
      # The implementation assumes that it is possible to move from
      # any register to any other register.
      #
      # If a dependency cycle is encountered, one of the following will
      # occur:
      #
      # - If the named register +tmp+ is set and is valid, it will be used
      #   as a temporary register.
      # - If +xchg+ is +true+, it is assumed that dependency cyles can
      #   be broken by swapping the contents of two register (aka the
      #   +xchg+ instruction on i386).
      # - If neither +xchg+ nor +tmp+ is set, try to find a register in
      #   +all_regs+ that is not involved in the cycle, use it as a
      #   temporary register.
      # - If the dependency cycle cannot be resolved as described above,
      #   an exception is raised.
      #
      # @param [Hash<Symbol, String => Object>] in_out
      #   Dictionary of desired register states.
      #   Keys are registers, values are either registers or any other value.
      # @param [Array<String>] all_regs
      #   List of all possible registers.
      #   Used to determine which values in +in_out+ are registers, versus
      #   regular values.
      # @option [String?] tmp
      #   Named register (or other sentinel value) to use as a temporary
      #   register.  If +tmp+ is a named register **and** appears
      #   as a source value in +in_out+, dependencies are handled
      #   appropriately.
      # @option [Boolean] xchg
      #   Indicates the existence of an instruction which can swap the
      #   registers.
      # @option [Boolean] randomize
      #   Randomize as much as possible about the order or registers.
      #
      # @return [Array]
      #   Array of instructions, see examples for more details.
      #
      # @example
      #   regs = %w(a b c d x y z)
      #   regsort({a: 1, b: 2}, regs)
      #   => [['mov', 'a', 1], ['mov', 'b', 2]]
      #   regsort({a: 'b', b: 'a'}, regs, tmp: 'X')
      #   => [['mov', 'X', 'a'], ['mov', 'a', 'b'], ['mov', 'b', 'X']]
      #   regsort({a: 1, b: 'a'}, regs)
      #   => [['mov', 'b', 'a'], ['mov', 'a', 1]]
      #   regsort({a: 'b', b: 'a', c: 3}, regs)
      #   => [['mov', 'c', 3], ['xchg', 'a', 'b']]
      #   regsort({a: 'b', b: 'a', c: 'b'}, regs)
      #   => [['mov', 'c', 'b'], ['xchg', 'a', 'b']]
      #   regsort({a: 'b', b: 'a', x: 'b'}, regs, tmp: 'y', xchg: false)
      #   => [['mov', 'x', 'b'],
      #       ['mov', 'y', 'a'],
      #       ['mov', 'a', 'b'],
      #       ['mov', 'b', 'y']]
      #   regsort({a: 'b', b: 'a', x: 'b'}, regs, tmp: 'x', xchg: false)
      #   => ArgumentError: Cannot break dependency cycles ...
      #   regsort({a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c'}, regs)
      #   => [['mov', 'x', '1'],
      #       ['mov', 'y', 'z'],
      #       ['mov', 'z', 'c'],
      #       ['xchg', 'a', 'b'],
      #       ['xchg', 'b', 'c']]
      #   regsort({a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c'}, regs, tmp: 'x')
      #   => [['mov', 'x', '1'],
      #       ['mov', 'z', 'c'],
      #       ['mov', 'x', 'a'],
      #       ['mov', 'a', 'b'],
      #       ['mov', 'b', 'c'],
      #       ['mov', 'c', 'x'],
      #       ['mov', 'y', 'z']]
      #   regsort({a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c'}, regs, xchg: false)
      #   => [['mov', 'x', '1'],
      #       ['mov', 'z', 'c'],
      #       ['mov', 'x', 'a'],
      #       ['mov', 'a', 'b'],
      #       ['mov', 'b', 'c'],
      #       ['mov', 'c', 'x'],
      #       ['mov', 'y', 'z']]
      def regsort(in_out, all_regs, tmp: nil, xchg: true, randomize: nil)
        # randomize = context.randomize if randomize.nil?

        # TODO(david942j): stringify_keys
        in_out = in_out.map { |k, v| [k.to_s, v] }.to_h
        # Drop all registers which will be set to themselves.
        # Ex. {eax: 'eax'}
        in_out.reject! { |k, v| k == v }

        # Check input
        if (in_out.keys - all_regs).any?
          raise ArgumentError, format('Unknown register! Know: %p.  Got: %p', all_regs, in_out)
        end

        # Collapse constant values
        #
        # Ex. {eax: 1, ebx: 1} can be collapsed to {eax: 1, ebx: 'eax'}.
        # +post_mov+ are collapsed registers, set their values in the end.
        post_mov = in_out.group_by { |_, v| v }.values.each_with_object({}) do |list, hash|
          val = list.first[1]
          # Special case for val.zero? because zeroify registers cost cheaper than mov.
          next if list.size == 1 || all_regs.include?(val) || val.zero?
          list.sort!
          first_reg, = list.shift
          list.each do |reg, _|
            hash[reg] = first_reg
            in_out.delete(reg)
          end
        end

        graph = in_out.dup
        result = []

        # Let's do the topological sort.
        # so sad ruby 2.1 doesn't have +itself+...
        deg = graph.values.group_by { |i| i }.map { |k, v| [k, v.size] }.to_h
        graph.keys.each { |k| deg[k] ||= 0 }

        until deg.empty?
          min_deg = deg.min_by { |_, v| v }[1]
          break unless min_deg.zero? # remain are all cycles
          min_pivs = deg.select { |_, v| v == min_deg }
          piv = randomize ? min_pivs.sample : min_pivs.first
          dst = piv.first
          deg.delete(dst)
          next unless graph.key?(dst) # Reach an end node.
          deg[graph[dst]] -= 1
          result << ['mov', dst, graph[dst]]
          graph.delete(dst)
        end

        # Remain must be cycles.
        cycles = graph.keys.each_with_object([]) do |reg, obj|
          next unless graph.key?(reg)
          cycle = check_cycle(reg, graph)
          obj << cycle
          cycle.each { |r| graph.delete(r) }
        end

        cycles.each do |cycle|
          # Try break a cycle
          # 1. If +tmp+ is set, try to use it.
          # 2. If +xchg == true+, use +xchg+.
          # 3. Find proper +tmp+ and use it.
          # 4. so sad :(.
          if tmp && !depends_on_cycle(tmp, in_out, cycle) then result.concat(break_cycle(cycle, tmp: tmp))
          elsif xchg then result.concat(break_cycle(cycle))
          else
            found_tmp = in_out.keys.find { |r| !depends_on_cycle(r, in_out, cycle) }
            raise ArgumentError, "Cannot break dependency cycles in #{in_out.inspect}" if found_tmp.nil?
            result.concat(break_cycle(cycle, tmp: found_tmp))
          end
        end

        # Now assign those collapsed registers.
        post_mov.sort.each do |dreg, sreg|
          result << ['mov', dreg, sreg]
        end

        result
      end

      private

      # Walk down the assignment list of a register,
      # return the path walked if it is encountered again.
      #
      # @return [Array<String>]
      #   The registers that involved in the cycle start from `reg`.
      #   Empty array will be returned if no cycle start and end at `reg`.
      # @example
      #   check_cycle('a', {'a' => 1}) #=> []
      #   check_cycle('a', {'a' => 'a'}) #=> ['a']
      #   check_cycle('a', {'a' => 'b', 'b' => 'c', 'c' => 'b', 'd' => 'a'}) #=> []
      #   check_cycle('a', {'a' => 'b', 'b' => 'c', 'c' => 'd', 'd' => 'a'})
      #   #=> ['a', 'b', 'c', 'd']
      def check_cycle(reg, assignments)
        check_cycle_(reg, assignments, [])
      end

      def check_cycle_(reg, assignments, path) # :nodoc:
        target = assignments[reg]
        path << reg
        # No cycle, some other value (e.g. 1)
        return [] unless assignments.key?(target)
        # Found a cycle
        return target == path.first ? path : [] if path.include?(target)
        check_cycle_(target, assignments, path)
      end

      # Check if any dependencies of +reg+ appears in cycles.
      def depends_on_cycle(reg, assignments, in_cycles)
        return false if reg.nil?
        loop do
          return true if in_cycles.include?(reg)
          reg = assignments[reg]
          break unless reg
        end
        false
      end

      def break_cycle(cycle, tmp: nil) # :nodoc:
        inst = tmp ? 'mov' : 'xchg'
        arr = tmp ? [tmp, *cycle, tmp] : cycle
        arr.each_cons(2).map { |dst, src| [inst, dst, src] }
      end
    end
  end
end
