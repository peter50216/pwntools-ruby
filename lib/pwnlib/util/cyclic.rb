# encoding: ASCII-8BIT
require 'pwnlib/util/packing'

module Pwnlib
  module Util
    # Generate string with easy-to-find pattern.
    module Cyclic
      # TODO(Darkpi): Should we put this constant in some 'String' module?
      ASCII_LOWERCASE = ('a'..'z').to_a.join

      module_function

      def de_bruijn(alphabet: ASCII_LOWERCASE, n: 4)
        return to_enum(__method__, alphabet: alphabet, n: n) { alphabet.size * n } unless block_given?
        k = alphabet.size
        a = [0] * (k * n)

        db = lambda do |t, p|
          if t > n
            (1..p).each { |j| yield alphabet[a[j]] } if n % p == 0
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

      def cyclic(length = nil, alphabet: ASCII_LOWERCASE, n: 4)
        enum = de_bruijn(alphabet: alphabet, n: n)
        r = length.nil? ? enum.to_a : enum.take(length)
        alphabet.is_a?(String) ? r.join : r
      end

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
  end
end
