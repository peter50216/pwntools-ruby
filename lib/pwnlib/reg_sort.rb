# encoding: ASCII-8BIT

require 'pwnlib/context'
require 'pwnlib/util/ruby'

module Pwnlib
  # Do topological sort on register assignments.
  module RegSort
    module_function

    # Sorts register dependencies.
    #
    # Given a dictionary of registers to desired register contents, return the optimal order in which to set the
    # registers to those contents.
    #
    # The implementation assumes that it is possible to move from any register to any other register.
    #
    # @param [Hash<Symbol, String => Object>] in_out
    #   Dictionary of desired register states.
    #   Keys are registers, values are either registers or any other value.
    # @param [Array<String>] all_regs
    #   List of all possible registers.
    #   Used to determine which values in +in_out+ are registers, versus regular values.
    # @param [Boolean] randomize
    #   Randomize as much as possible about the order or registers.
    #
    # @return [Array]
    #   Array of instructions, see examples for more details.
    #
    # @example
    #   regs = %w(a b c d x y z)
    #   regsort({a: 1, b: 2}, regs)
    #   => [['mov', 'a', 1], ['mov', 'b', 2]]
    #   regsort({a: 'b', b: 'a'}, regs)
    #   => [['xchg', 'a', 'b']]
    #   regsort({a: 1, b: 'a'}, regs)
    #   => [['mov', 'b', 'a'], ['mov', 'a', 1]]
    #   regsort({a: 'b', b: 'a', c: 3}, regs)
    #   => [['mov', 'c', 3], ['xchg', 'a', 'b']]
    #   regsort({a: 'b', b: 'a', c: 'b'}, regs)
    #   => [['mov', 'c', 'b'], ['xchg', 'a', 'b']]
    #   regsort({a: 'b', b: 'c', c: 'a', x: '1', y: 'z', z: 'c'}, regs)
    #   => [['mov', 'x', '1'],
    #       ['mov', 'y', 'z'],
    #       ['mov', 'z', 'c'],
    #       ['xchg', 'a', 'b'],
    #       ['xchg', 'b', 'c']]
    #
    # @diff We don't support +tmp+/+xchg+ options because there's no such usage at all.
    def regsort(in_out, all_regs, randomize: nil)
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

      # Collapse constant values.
      #
      # Ex. {eax: 1, ebx: 1} can be collapsed to {eax: 1, ebx: 'eax'}.
      # +post_mov+ are collapsed registers, set their values in the end.
      post_mov = in_out.group_by { |_, v| v }.each_value.with_object({}) do |list, hash|
        list.sort!
        first_reg, val = list.shift
        # Special case for val.zero? because zeroify registers is cheaper than mov.
        next if list.empty? || all_regs.include?(val) || val.zero?
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
      graph.each_key { |k| deg[k] ||= 0 }

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
      graph.each_key do |reg|
        cycle = check_cycle(reg, graph)
        cycle.each_cons(2) do |d, s|
          result << ['xchg', d, s]
        end
        cycle.each { |r| graph.delete(r) }
      end

      # Now assign those collapsed registers.
      post_mov.sort.each do |dreg, sreg|
        result << ['mov', dreg, sreg]
      end

      result
    end

    Pwnlib::Util::Ruby.private_class_method_block do
      # Walk down the assignment list of a register, return the path walked if it is encountered again.
      #
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
        # No cycle, some other value (e.g. 1).
        return [] unless assignments.key?(target)
        # Found a cycle.
        return target == path.first ? path : [] if path.include?(target)
        check_cycle_(target, assignments, path)
      end
    end
  end
end
