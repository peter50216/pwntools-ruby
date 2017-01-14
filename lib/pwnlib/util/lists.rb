# encoding: ASCII-8BIT

require 'pwnlib/context'

module Pwnlib
  module Util
    # Methods related to group / slice string into lists.
    # See {ClassMethods} for method details.
    module Lists
      # @note Do not create and call instance method here. Instead, call module method on {Lists}.
      module ClassMethods
        # Split sequence into subsequences of given size. If the values cannot be
        # evenly distributed among into groups, then the last group will either be
        # returned as is or padded with the value specified in +fill_value+.
        #
        # @param [Integer] n
        #   The desired size of each subsequences.
        # @param [String] str
        #   The sequence to be grouped.
        # @option [Symbol] underfull_action
        #   Available options are +:ignore+, +:drop+, and +:fill+.
        # @option [String] fill_value
        #   The padding byte.
        #   Only meaningful when +str+ cannot be grouped equally and
        #   +underfull_action == :fill+.
        #
        # @return [Array<String>]
        #   The split result.
        # @example
        #  slice(2, 'ABCDE') #=> ['AB', 'CD', 'E']
        #  slice(2, 'ABCDE', underfull_action: :fill, fill_value: 'X')
        #  => ['AB', 'CD', 'EX']
        #  slice(2, 'ABCDE', underfull_action: :drop)
        #  => ['AB', 'CD']
        # @diff This method named +group+ in python-pwntools, but
        #   I think this actually more like the +Array#each_slice+ in ruby.
        def slice(n, str, underfull_action: :ignore, fill_value: nil)
          unless %i(ignore drop fill).include?(underfull_action)
            raise ArgumentError, 'underfull_action expect to be one of :ignore, :drop, and :fill'
          end
          sliced = str.chars.each_slice(n).map(&:join)
          case underfull_action
          when :drop
            sliced.pop unless sliced.last.size == n
          when :fill
            remain = n - sliced.last.size
            raise ArgumentError, 'fill_value must be a character' unless fill_value.to_s.size == 1
            sliced.last.concat(fill_value * remain)
          end
          sliced
        end
        alias group slice
      end

      extend ClassMethods
    end
  end
end
