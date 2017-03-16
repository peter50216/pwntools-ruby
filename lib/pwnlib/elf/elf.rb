require 'elftools'
require 'rainbow'

module Pwnlib
  # ELF module includes classes related to parsing ELF.
  module ELF
    # Main class for using {Pwnlib::ELF} module.
    class ELF
      # Instantiate an {Pwnlib::ELF::ELF} object.
      #
      # Will show checksec information to stdout instantiate.
      # @param [String] path
      #   The path to the ELF file.
      # @example
      #   Pwnlib::ELF::ELF.new('/lib/x86_64-linux-gnu/libc.so.6')
      #   TODO(david942j): checksec information.
      def initialize(path)
        @elf_file = ELFTools::ELFFile.new(File.open(path, 'rb')) # rubocop:disable Style/AutoResourceCleanup
        puts checksec
      end

      # Return the protection information,
      # wrapper with color codes.
      # @return [String] The checksec infor.
      def checksec
        [
          'RELRO:'.ljust(10) + {
            'Full' => Rainbow('Full RELRO').green,
            'Partial' => Rainbow('Partial RELRO').yellow,
            'None' => Rainbow('No RELRO').red
          }[relro],
          'Stack:'.ljust(10) + {
            true =>  Rainbow('Canary found').green,
            false => Rainbow('No canary found').red
          }[canary?],
          'NX:'.ljust(10) + {
            true => Rainbow('NX enabled').green,
            false => Rainbow('NX disabled').red
          }[nx?],
          'PIE:'.ljust(10) + {
            true => Rainbow('PIE enabled').green,
            false => Rainbow('No PIE').red
          }[pie?]
        ].join("\n")
      end

      # The method used in relro.
      # @return [String]
      def relro
        return 'Full' if dynamic_tag(:bind_now)
        return 'Partial' if @elf_file.segment_by_type(:gnu_relro)
        'None'
      end

      # Is this ELF file has canary?
      #
      # Actually judged by if +__stack_chk_fail+ in symbols.
      # @return [Boolean]
      def canary?
        true
      end

      # Is this ELF file stack executable?
      # @return [Boolean]
      def nx?
        !@elf_file.segment_by_type(:gnu_stack).executable?
      end

      # Is this ELF file a position-independent executable?
      # @return [Boolean]
      def pie?
        @elf_file.elf_type == 'DYN'
      end

      # There's too much, let pry now show so much information.
      def inspect
        nil
      end

      private

      # Get the dynamic tag with +type+.
      # @return [ELFTools::Dynamic::Tag, NilClass]
      def dynamic_tag(type)
        dynamic = @elf_file.segment_by_type(:dynamic) || @elf.section_by_name('.dynamic')
        return nil if dynamic.nil? # No dynamic present, might be static-linked.
        dynamic.tag_by_type(type)
      end
    end
  end
end
