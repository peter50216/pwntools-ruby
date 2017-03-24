require 'elftools'
require 'rainbow'
require 'ostruct'

module Pwnlib
  # ELF module includes classes related to parsing ELF.
  module ELF
    # Main class for using {Pwnlib::ELF} module.
    class ELF
      # @return [OpenStruct] GOT symbols.
      attr_reader :got

      # @return [OpenStruct] PLT symbols.
      attr_reader :plt

      # @return [OpenStruct] All symbols.
      attr_reader :symbols

      # @return [Integer] Base address
      attr_accessor :address

      # Instantiate an {Pwnlib::ELF::ELF} object.
      #
      # Will show checksec information to stdout instantiate.
      #
      # @param [String] path
      #   The path to the ELF file.
      # @param [Boolean] checksec
      #   The checksec information will be printed to stdout when loaded ELF. Pass +checksec: false+ to disable this
      #   feature.
      #
      # @example
      #   ELF.new('/lib/x86_64-linux-gnu/libc.so.6')
      #   # RELRO:    Partial RELRO
      #   # Stack:    No canary found
      #   # NX:       NX enabled
      #   # PIE:      PIE enabled
      #   # => #<Pwnlib::ELF::ELF:0x00559bd670dcb8>
      def initialize(path, checksec: true)
        @elf_file = ELFTools::ELFFile.new(File.open(path, 'rb')) # rubocop:disable Style/AutoResourceCleanup
        load_got
        load_plt
        load_symbols
        @address = base_address
        show_info if checksec
      end

      # Set the base address.
      #
      # Values in following tables will be changed simultaneously:
      #   got
      #   plt
      #   symbols
      #
      # @param [Integer] new
      #   Address to be changed to.
      #
      # @return [void]
      def address=(new)
        old = @address
        @address = new
        [@got, @plt, @symbols].each do |tbl|
          tbl.each_pair { |k, _| tbl[k] += new - old }
        end
        new
      end

      # Return the protection information, wrapper with color codes.
      #
      # @return [String]
      #   The checksec information.
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
            false => Rainbow(format('No PIE (0x%x)', address)).red
          }[pie?]
        ].join("\n")
      end

      # The method used in relro.
      #
      # @return [String]
      def relro
        return 'Full' if dynamic_tag(:bind_now)
        return 'Partial' if @elf_file.segment_by_type(:gnu_relro)
        'None'
      end

      # Is this ELF file has canary?
      #
      # Actually judged by if +__stack_chk_fail+ in got symbols.
      #
      # @return [Boolean] Yes or not.
      def canary?
        @got.respond_to?('__stack_chk_fail')
      end

      # Is this ELF file stack executable?
      #
      # @return [Boolean]
      def nx?
        !@elf_file.segment_by_type(:gnu_stack).executable?
      end

      # Is this ELF file a position-independent executable?
      #
      # @return [Boolean]
      def pie?
        @elf_file.elf_type == 'DYN'
      end

      # There's too much objects inside, let pry not so verbose.
      def inspect
        nil
      end

      private

      def show_info
        # TODO: Use logger?
        puts checksec
      end

      # Get the dynamic tag with +type+.
      # @return [ELFTools::Dynamic::Tag, NilClass]
      def dynamic_tag(type)
        dynamic = @elf_file.segment_by_type(:dynamic) || @elf.section_by_name('.dynamic')
        return nil if dynamic.nil? # No dynamic present, might be static-linked.
        dynamic.tag_by_type(type)
      end

      # Load got symbols
      def load_got
        @got = OpenStruct.new
        sections_by_types(%i(rel rela)).each do |rel_sec|
          symtab = @elf_file.section_at(rel_sec.header.sh_link)
          next unless symtab.respond_to?(:symbol_at)
          rel_sec.relocations.each do |rel|
            symbol = symtab.symbol_at(rel.symbol_index)
            next unless symbol
            @got[symbol.name] = rel.header.r_offset
          end
        end
      end

      # Load all plt symbols.
      def load_plt
        # Unlike pwntools-python, which use unicorn emulating instructions to find plt(s).
        # Here only use section information, which won't find any plt(s) when compile option '-Wl' is enabled.
        #
        # The implementation here same as python-pwntools 3.5, and supports i386 and amd64 only.
        @plt = OpenStruct.new
        plt_sec = @elf_file.section_by_name('.plt')
        return if plt_sec.nil? # TODO: log.warn
        rel_sec = @elf_file.section_by_name('.rel.plt') || @elf_file.section_by_name('.rela.plt')
        return if rel_sec.nil? # -Wl enabled
        symtab = @elf_file.section_at(rel_sec.header.sh_link)
        address = plt_sec.header.sh_addr + 0x10 # magic offset, correct in i386/amd64
        rel_sec.relocations.each do |rel|
          symbol = symtab.symbol_at(rel.symbol_index)
          @plt[symbol.name] = address
          address += 0x10 # magic gap again
        end
      end

      # Load all exist symbols.
      def load_symbols
        @symbols = OpenStruct.new
        @elf_file.each_sections do |section|
          next unless section.respond_to?(:symbols)
          section.each_symbols do |symbol|
            # Don't care symbols without name.
            next if symbol.name.empty?
            next if symbol.header.st_value.zero?
            @symbols[symbol.name] = symbol.header.st_value
          end
        end
      end

      def sections_by_types(types)
        types.map { |type| @elf_file.sections_by_type(type) }.flatten
      end

      def base_address
        return 0 if pie?
        # Find the min of PT_LOAD's p_vaddr
        @elf_file.segments_by_type(:load)
                 .map { |seg| seg.header.p_vaddr }
                 .select { |addr| addr > 0 }
                 .min
      end
    end
  end
end
