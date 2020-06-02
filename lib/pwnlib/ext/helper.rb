# encoding: ASCII-8BIT
# frozen_string_literal: true

module Pwnlib
  module Ext
    # Helper methods for defining extension.
    module Helper
      def def_proxy_method(mod, *ms, **m2)
        ms.flatten
          .map { |x| [x, x] }
          .concat(m2.to_a)
          .each do |method, proxy_to|
            class_eval(<<-EOS, __FILE__, __LINE__ + 1)
              def #{method}(*args, **kwargs, &block)
              #{mod}.#{proxy_to}(self, *args, **kwargs, &block)
              end
            EOS
          end
      end
    end
  end
end
