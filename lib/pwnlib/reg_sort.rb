# encoding: ASCII-8BIT

require 'pwnlib/context'

module Pwnlib
  # Topographical sort
  module RegSort
    # @note Do not create and call instance method here. Instead, call module method on {RegSort}.
    module ClassMethod
      # Walk down the assignment list of a register,
      # return the path walked if it is encountered again.
      #
      # @return [Array]
      #   The registers that involved in the cycle start from `reg`.
      #   Empty array will be returned if no cycle start and end at `reg`.
      # @example
      #   check_cycle('a', {a: 1}) #=> []
      #   check_cycle('a', {a: 'a'}) #=> ['a']
      #   check_cycle('a', {a: 'b', b: 'c', c: 'b', d: 'a'}) #=> []
      #   check_cycle('a', {a: 'b', b: 'c', c: 'd', d: 'a'})
      #   #=> ['a', 'b', 'c', 'd']
      def check_cycle(reg, assignments)
        check_cycle_(reg, assignments, [])
      end

      def check_cycle_(reg, assignments, path) # :nodoc:
        target = assignments[reg.to_sym]
        path << reg
        # No cycle, some other value (e.g. 1)
        return [] unless assignments.key?(target.to_sym)
        # Found a cycle
        return target == path[0] ? path : [] if path.include?(target)
        check_cycle_(reg, assignments, path)
      end

      # Return a list of all registers which directly
      # depend on the specified register.
      # @example
      #  extract_dependencies('a', {a: 1})
      #  => []
      #  extract_dependencies('a', {a: 'b', b: 1})
      #  => []
      #  extract_dependencies('a', {a: 1, b: 'a'})
      #  => ['b']
      #  extract_dependencies('a', {a: 1, b: 'a', c: 'a'})
      #  => ['b', 'c']
      def extract_dependencies(reg, assignments)
        # .sort is only for determinism
        assignments.select { |_, v| v == reg }.keys.map(&:str).sort
      end

      # Resolve the order of all dependencies starting at a given register.
      #
      # @example
      #   deps = {a: [], b: [], c: ['b'], d: ['c', 'x'], x: []}
      #   resolve_order('a', deps)
      #   => ['a']
      #   resolve_order('b', deps)
      #   => ['b']
      #   resolve_order('c', deps)
      #   => ['b', 'c']
      #   resolve_order('d', deps)
      #   => ['b', 'c', 'x', 'd']
      def resolve_order(reg, deps)
        deps[reg.to_sym].map { |dep| resolve_order(dep, deps) }.flatten + [reg]
      end

      # Check if any dependencies of `reg` appears in cycles.
      def depends_on_cycle(reg, assignments, in_cycles)
        return false if reg.nil?
        loop do
          return true if in_cycles.include?(reg)
          reg = assignments[reg.to_sym]
          break unless reg
        end
        false
      end

      def regsort(in_out, all_regs, tmp: nil, xchg: true, randomize: nil)
        # randomize = context.randomize if randomize.nil?

        # Drop all registers which will be set to themselves.
        # For example, {eax: 'eax'}
        in_out.select! { |k, v| k.to_s == v }

        # Collapse constant values
        #
        # For eaxmple, {eax: 0, ebx: 0} => {eax: 0, ebx: 'eax'}
        v_k = Hash.new { |k, v| k[v] = [] }
        in_out.sort.each do |k, v|
          v_k[v] << k if !all_regs.include?(v) && v != 0
        end
        post_mov = {}
        v_k.sort.each do |_, ks|
          1.upto(ks.size - 1) do |i|
            post_mov[ks[i]] = ks[0]
            in_out.delete ks[i]
          end
        end

        # Check input
        if (in_out.keys - all_regs).any?
          raise ArgumentError, format('Unknown register! Know: %s.  Got: %s', all_regs.inspect, in_out.inspect)
        end

        # In the simplest case, no registers are 'inputs'
        # which are also 'outputs'.
        #
        # For example, {eax: 1, ebx: 2, ecx: 'edx'}
        unless in_out.values.any? { |v| in_out.key?(v.to_sym) }
          result = in_out.sort.map { |k, v| ['mov', k, v] }
          result.shuffle! if randomize
          post_mov.sort.each do |dreg, sreg|
            result << ['mov', dreg, sreg]
          end
          return result
        end

        # Invert so we have a dependency graph.
        #
        # Input:   {'A': 'B', 'B': '1', 'C': 'B'}
        # Output:  {'A': [], 'B': ['A', 'C'], 'C': []}
        #
        # In this case, both A and C must be set before B.
        deps = in_out.each_with_object({}) { |r, h| h[r] = extract_dependencies(r, in_out) }

        # Final result which will be returned.
        result = []

        # Find all cycles.
        #
        # Given that everything is single-assignment, the cycles
        # are guarnteed to be disjoint.
        cycle_candidates = in_out.keys.sort
        cycles           = []
        in_cycle         = []
        not_in_cycle     = []
        cycle_candidates.shuffle! if randomize

        while cycle_candidates.any?
          reg   = cycle_candidates[0]
          cycle = check_cycle(reg, in_out)
          next not_in_cycle.push(cycle_candidates.shift) if cycle.empty?
          cycle.rotate!(rand(cycle.size)) if randomize
          cycles << cycle
          in_cycle.concat cycle
          cycle_candidates -= cycle
        end

        # If there are cycles, ensure that we can break them.
        #
        # If the temporary register itself is in, or ultimately
        # depends on a register which is in a cycle, we cannot use
        # it as a temporary register.
        #
        # In this example below, X, Y, or Z cannot be a temporary register,
        # as the following must occur before resolving the cycle:
        #
        #  - X = Y
        #  - Y = Z
        #  - Z = C
        #
        #   X → Y → Z → ───╮
        #                  ↓
        #  ╭─ (A) → (B) → (C) ─╮
        #  ╰──────── ← ────────╯
        tmp = nil if depends_on_cycle(tmp, in_out, in_cycle)

        # If XCHG is expressly disabled, and there is no temporary register,
        # try to see if there is any register which can be used as a temp
        # register instead.
        unless xchg || tmp
          tmp = in_out.keys.find { |r| !depends_on_cycle(r, in_out, in_cycle) }
          raise ArgumentError, "Cannot break dependency cycles in #{in_out.sort.inspect}" if tmp.nil?
        end

        # Don't set the temporary register now
        not_in_cycle.delete tmp

        # Resolve everything *not* in a cycle.
        not_in_cycle.shuffle! if randomize
        while not_in_cycle.any?
          order = resolve_order(not_in_cycle[0], deps)
          order.each do |regi|
            # Did we already handle this reg?
            next unless not_in_cycle.include?(regi)
            src =  in_out[regi]
            result << ['mov', regi, src]
            not_in_cycle.delete regi
            # Mark this as resolved
            deps[src].delete(regi) if deps.key?(src)
          end
        end

        # If using a temporary register, break each cycle individually
        #
        #  ╭─ (A) → (B) → (C) ─╮
        #  ╰──────── ← ────────╯
        #
        # Becomes separete actions:
        #
        #   tmp = A
        #   A = B
        #   B = C
        #   C = tmp
        #
        #  ╭─ (A) → (B) → (C) ─╮
        #  ╰──────── ← ────────╯
        cycles.shuffle! if randomize
        if tmp
          cycles.each do |cyc|
            first = cyc[0]
            last = cyc[-1]
            deps[first].delete last
            in_out[last] = tmp
            order = resolve_order(last, deps)
            result << ['mov', tmp, first]
            order.each { |r| result << ['mov', r, in_out[r]] }
          end
        else
          cycles.each do |cyc|
            (cyc.size - 1).times do |i|
              result << ['xchg', cyc[i], cyc[i + 1]]
            end
          end
        end

        # Finally, set the temp register's final value
        result << ['mov', tmp, in_out[tmp]] if in_out.key?(tmp)

        post_mov.sort.each do |dreg, sreg|
          result << ['mov', dreg, sreg]
        end
        result
      end
    end
  end
end
