require 'elftools'
require 'ostruct'
require 'rainbow'

module Pwnlib
  # ELF module includes classes for parsing an ELF file.
  module ELF
    # Main class for using {Pwnlib::ELF} module.
    class ELF
      # @return [OpenStruct] GOT symbols.
      attr_reader :got

      # @return [OpenStruct] PLT symbols.
      attr_reader :plt

      # @return [OpenStruct] All symbols.
      attr_reader :symbols

      # @return [Integer] Base address.
      attr_reader :address

      # Instantiate an {Pwnlib::ELF::ELF} object.
      #
      # Will show checksec information to stdout.
      #
      # @param [String] path
      #   The path to the ELF file.
      # @param [Boolean] checksec
      #   The checksec information will be printed to stdout after ELF loaded. Pass +checksec: false+ to disable this
      #   feature.
      #
      # @example
      #   ELF.new('/lib/x86_64-linux-gnu/libc.so.6')
      #   # RELRO:    Partial RELRO
      #   # Stack:    No canary found
      #   # NX:       NX enabled
      #   # PIE:      PIE enabled
      #   #=> #<Pwnlib::ELF::ELF:0x00559bd670dcb8>
      def initialize(path, checksec: true)
        @elf_file = ELFTools::ELFFile.new(File.open(path, 'rb')) # rubocop:disable Style/AutoResourceCleanup
        load_got
        load_plt
        load_symbols
        @address = base_address
        @load_addr = @address
        show_info if checksec
      end

      # Set the base address.
      #
      # Values in following tables will be changed simultaneously:
      #   got
      #   plt
      #   symbols
      #
      # @param [Integer] val
      #   Address to be changed to.
      #
      # @return [Integer]
      #   The new address.
      def address=(val)
        old = @address
        @address = val
        [@got, @plt, @symbols].each do |tbl|
          tbl.each_pair { |k, _| tbl[k] += val - old }
        end
        val
      end

      # Return the protection information, wrapper with color codes.
      #
      # @return [String]
      #   The checksec information.
      def checksec
        [
          'RELRO:'.ljust(10) + {
            full: Rainbow('Full RELRO').green,
            partial: Rainbow('Partial RELRO').yellow,
            none: Rainbow('No RELRO').red
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
      # @return [:full, :partial, :none]
      def relro
        return :full if dynamic_tag(:bind_now)
        return :partial if @elf_file.segment_by_type(:gnu_relro)
        :none
      end

      # Is this ELF file has canary?
      #
      # Actually judged by if +__stack_chk_fail+ in got symbols.
      #
      # @return [Boolean] Yes or not.
      def canary?
        @got.respond_to?('__stack_chk_fail')
      end

      # Is stack executable?
      #
      # @return [Boolean] Yes or not.
      def nx?
        !@elf_file.segment_by_type(:gnu_stack).executable?
      end

      # Is this ELF file a position-independent executable?
      #
      # @return [Boolean] Yes or not.
      def pie?
        @elf_file.elf_type == 'DYN'
      end

      # There's too many objects inside, let pry not so verbose.
      # @return [nil]
      def inspect
        nil
      end

      # Yields the ELF's virtual address space for the specified string or regexp.
      # Returns an Enumerator if no block given.
      #
      # @param [String, Regexp] needle
      #   The specified string to search.
      #
      # @return [Enumerator<Integer>]
      #   An enumerator for offsets in ELF's virtual address space.
      #
      # @example
      #   ELF.new('/bin/sh', checksec: false).find('ELF')
      #   #=> #<Enumerator: ...>
      #
      #   ELF.new('/bin/sh', checksec: false).find(/E.F/).each { |i| puts i.hex }
      #   # 0x1
      #   # 0x11477
      #   # 0x1c84f
      #   # 0x1d5ee
      #   #=> true
      def search(needle)
        return enum_for(:search, needle) unless block_given?
        load_address_fixup = @address - @load_addr
        stream = @elf_file.stream
        @elf_file.each_segments do |seg|
          addr = seg.header.p_vaddr
          memsz = seg.header.p_memsz
          offset = seg.header.p_offset

          stream.pos = offset
          data = stream.read(memsz).ljust(seg.header.p_filesz, "\x00")

          offset = 0
          loop do
            offset = data.index(needle, offset)
            break if offset.nil?
            yield (addr + offset + load_address_fixup)
            offset += 1
          end
        end
        true
      end
      alias find search

      private

      def show_info
        # TODO: Use logger?
        puts checksec
      end

      # Get the dynamic tag with +type+.
      # @return [ELFTools::Dynamic::Tag, nil]
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
            next if symbol.nil? # Unusual case.
            @got[symbol.name] = rel.header.r_offset
          end
        end
      end

      PLT_OFFSET = 0x10 # magic offset, correct in i386/amd64.
      # Load all plt symbols.
      def load_plt
        # Unlike pwntools-python, which use unicorn emulating instructions to find plt(s).
        # Here only use section information, which won't find any plt(s) when compile option '-Wl' is enabled.
        #
        # The implementation here same as python-pwntools 3.5, and supports i386 and amd64 only.
        @plt = OpenStruct.new
        plt_sec = @elf_file.section_by_name('.plt')
        return if plt_sec.nil? # TODO(david942j): log.warn
        rel_sec = @elf_file.section_by_name('.rel.plt') || @elf_file.section_by_name('.rela.plt')
        return if rel_sec.nil? # -Wl enabled
        symtab = @elf_file.section_at(rel_sec.header.sh_link)
        return unless symtab.respond_to?(:symbol_at)
        address = plt_sec.header.sh_addr + PLT_OFFSET
        rel_sec.relocations.each do |rel|
          symbol = symtab.symbol_at(rel.symbol_index)
          next if symbol.nil? # Unusual case.
          @plt[symbol.name] = address
          address += PLT_OFFSET
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
            # TODO(david942j): handle symbols with same name.
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
                 .min
      end
    end
  end
end
