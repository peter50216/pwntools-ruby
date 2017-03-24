# encoding: ASCII-8BIT

module Pwnlib
  module Util
    # Generate string with easy-to-find pattern.
    # See {ClassMethods} for method details.
    #
    # @example Call by specifying full module path.
    #   require 'pwnlib/util/cyclic'
    #   Pwnlib::Util::Cyclic.cyclic_find(Pwnlib::Util::Cyclic.cyclic(200)[123, 4]) #=> 123
    # @example require 'pwn' and have all methods.
    #   require 'pwn'
    #   cyclic_find(cyclic(200)[123, 4]) #=> 123
    module Cyclic
      # @note Do not create and call instance method here. Instead, call module method on {Cyclic}.
      module ClassMethods
        # TODO(Darkpi): Should we put this constant in some 'String' module?
        ASCII_LOWERCASE = ('a'..'z').to_a.join
        private_constant :ASCII_LOWERCASE

        # Generator for a sequence of unique substrings of length +n+.
        # This is implemented using a De Bruijn Sequence over the given +alphabet+.
        # Returns an Enumerator if no block given.
        #
        # @overload de_bruijn(alphabet: ASCII_LOWERCASE, n: 4)
        #   @param [String, Array] alphabet
        #     Alphabet to be used.
        #   @param [Integer] n
        #     Length of substring that should be unique.
        #
        #   @return [void]
        #   @yieldparam c
        #     Item of the result sequence in order.
        #
        # @overload de_bruijn(alphabet: ASCII_LOWERCASE, n: 4)
        #   @param [String, Array] alphabet
        #     Alphabet to be used.
        #   @param [Integer] n
        #     Length of substring that should be unique.
        #
        #   @return [Enumerator]
        #     The result sequence.
        def de_bruijn(alphabet: ASCII_LOWERCASE, n: 4)
          return to_enum(__method__, alphabet: alphabet, n: n) { alphabet.size**n } unless block_given?
          k = alphabet.size
          a = [0] * (k * n)

          db = lambda do |t, p|
            if t > n
              (1..p).each { |j| yield alphabet[a[j]] } if (n % p).zero?
            else
              a[t] = a[t - p]
              db.call(t + 1, p)
              (a[t - p] + 1...k).each do |j|
                a[t] = j
                db.call(t + 1, t)
              end
            end
          end

          db[1, 1]
        end

        # Simple wrapper over {#de_bruijn}, returning at most +length+ items.
        #
        # @param [Integer, nil] length
        #   Desired length of the sequence,
        #   or +nil+ for the entire sequence.
        # @param [String, Array] alphabet
        #   Alphabet to be used.
        # @param [Integer] n
        #   Length of substring that should be unique.
        #
        # @return [String, Array]
        #   The result sequence of at most +length+ items,
        #   with same type as +alphabet+.
        #
        # @example
        #   cyclic(alphabet: 'ABC', n: 3) #=> 'AAABAACABBABCACBACCBBBCBCCC'
        #   cyclic(20) #=> 'aaaabaaacaaadaaaeaaa'
        def cyclic(length = nil, alphabet: ASCII_LOWERCASE, n: 4)
          enum = de_bruijn(alphabet: alphabet, n: n)
          r = length.nil? ? enum.to_a : enum.take(length)
          alphabet.is_a?(String) ? r.join : r
        end

        # Find the position of a substring in a De Bruijn sequence
        #
        # @param [String, Array] subseq
        #   The substring to be found in the sequence.
        # @param [String, Array] alphabet
        #   Alphabet to be used.
        # @param [Integer] n
        #   Length of substring that should be unique.
        #   Default to +subseq.size+.
        #
        # @return [Integer, nil]
        #   The index +subseq+ first appear in the sequence,
        #   or +nil+ if not found.
        #
        # @todo Speed! See comment in Python pwntools.
        #
        # @example
        #   cyclic_find(cyclic(300)[217, 4]) #=> 217
        def cyclic_find(subseq, alphabet: ASCII_LOWERCASE, n: nil)
          n ||= subseq.size
          subseq = subseq.chars if subseq.is_a?(String)
          return nil unless subseq.all? { |c| alphabet.include?(c) }

          pos = 0
          saved = []
          de_bruijn(alphabet: alphabet, n: n).each do |c|
            saved << c
            if saved.size > subseq.size
              saved.shift
              pos += 1
            end
            return pos if saved == subseq
          end
          nil
        end
      end

      extend ClassMethods
    end
  end
end
