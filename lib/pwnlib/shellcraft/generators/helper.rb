require 'pwnlib/abi'
require 'pwnlib/constants/constants'
require 'pwnlib/context'
require 'pwnlib/reg_sort'
require 'pwnlib/shellcraft/registers'
require 'pwnlib/util/fiddling'
require 'pwnlib/util/lists'
require 'pwnlib/util/packing'

module Pwnlib
  module Shellcraft
    module Generators
      # Define methods for generator modules.
      #
      # This module must and can only be extended by Common or Linux module under {Generators}.
      module Helper
        # Provide a 'sandbox' for generators.
        class Runner
          class << self
            def label_num
              @label_num ||= 0
              @label_num += 1
            end
          end

          def clear
            @_output = StringIO.new
          end

          # Indent each line 2 space.
          def typesetting
            indent = @_output.string.lines.map do |line|
              next line.strip + "\n" if label_str?(line.strip)
              line == "\n" ? line : ' ' * 2 + line.lstrip
            end
            indent.join
          end

          private

          def cat(str)
            @_output.puts(str)
          end

          # @example
          #   get_label('infloop') #=> 'infloop_1'
          def get_label(str)
            "#{str}_#{self.class.label_num}"
          end

          def okay(s, *a, **kw)
            s = pack(s, *a, **kw) if s.is_a?(Integer)
            !(s.include?("\x00") || s.include?("\n"))
          end

          def evaluate(item)
            return item if register?(item)
            Constants.eval(item)
          end

          # @param [Constants::Constant, String, Integer] n
          def pretty(n)
            case n
            when Constants::Constant
              format('%s /* %s */', pretty(n.to_i), n)
            when Integer
              n.abs < 10 ? n.to_s : hex(n)
            else
              n.inspect
            end
          end

          def label_str?(str)
            str.match(/\A\w+_\d+:\Z/) != nil
          end

          include ::Pwnlib::Context
          include ::Pwnlib::RegSort
          include ::Pwnlib::Shellcraft::Registers
          include ::Pwnlib::Util::Fiddling
          include ::Pwnlib::Util::Lists
          include ::Pwnlib::Util::Packing
        end

        class << self
          # Define a corresponding singleton method whenever a instance method is defined.
          def extended(mod)
            class << mod
              define_method(:method_added) do |m|
                # Define singleton methods, so we can invoke +Generators::X86::Common.pushstr_array+.
                # Each method runs in an independent 'runner', so methods would not effect each other.
                runner = Runner.new
                method = instance_method(m).bind(runner)
                define_singleton_method(m) do |*args|
                  runner.clear
                  method.call(*args)
                  runner.typesetting
                end
              end
            end
          end
        end
      end
    end
  end
end
