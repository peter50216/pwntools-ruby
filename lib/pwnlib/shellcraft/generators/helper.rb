require 'pwnlib/context'

module Pwnlib
  module Shellcraft
    module Generators
      # Define methods for generator modules.
      module Helper
        class << self
          # Hook the return value of all singleton methods in the extendee module.
          # With this we don't need to take care of the typesetting of generated assemblies.
          def extended(mod)
            hooked = {}
            # Hook all methods' return value
            mod.define_singleton_method(:singleton_method_added) do |m|
              next if m == :singleton_method_added || hooked[m]
              hooked[m] = mod.method(m)
              mod.define_singleton_method(m) do |*args|
                @_output = StringIO.new
                hooked[m].call(*args)
                Helper.typesetting(@_output.string)
              end
            end
          end

          # Indent each line 2 space.
          def typesetting(str)
            indent = str.lines.map do |line|
              next line.strip + "\n" if label_str?(line.strip)
              line == "\n" ? line : ' ' * 2 + line.lstrip
            end
            indent.join
          end

          def label_str?(str)
            str.match(/\A\w+_\d+:\Z/) != nil
          end
        end

        private

        def cat(str)
          @_output.puts(str)
        end

        # @example
        #   get_label('infloop') #=> 'infloop_1'
        def get_label(str)
          @label_num ||= 0
          @label_num += 1
          "#{str}_#{@label_num}"
        end

        def okay(s, *a, **kw)
          s = Util::Packing.pack(s, *a, **kw) if s.is_a?(Integer)
          !(s.include?("\x00") || s.include?("\n"))
        end

        def evaluate(item)
          return item if ::Pwnlib::Shellcraft::Registers.register?(item)
          Constants.eval(item)
        end

        # @param [Constants::Constant, String, Integer] n
        def pretty(n)
          case n
          when Constants::Constant
            format('%s /* %s */', pretty(n.to_i), n)
          when Integer
            n.abs < 10 ? n.to_s : Util::Fiddling.hex(n)
          else
            n.inspect
          end
        end

        include ::Pwnlib::Context
      end
    end
  end
end
