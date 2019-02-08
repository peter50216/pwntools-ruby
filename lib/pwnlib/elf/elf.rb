require 'ostruct'

require 'elftools'
require 'one_gadget/one_gadget'
require 'rainbow'

require 'pwnlib/logger'

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
        @path = File.realpath(path)
        @elf_file = ELFTools::ELFFile.new(File.open(path, 'rb'))
        load_got
        load_plt
        load_symbols
        @address = base_address
        @load_addr = @address
        @one_gadgets = nil
        show_info(@path) if checksec
      end

      # Set the base address.
      #
      # Values in following tables will be changed simultaneously:
      #   got
      #   plt
      #   symbols
      #   one_gadgets
      #
      # @param [Integer] val
      #   Address to be changed to.
      #
      # @return [Integer]
      #   The new address.
      def address=(val)
        old = @address
        @address = val
        [@got, @plt, @symbols].compact.each do |tbl|
          tbl.each_pair { |k, _| tbl[k] += val - old }
        end
        @one_gadgets.map! { |off| off + val - old } if @one_gadgets
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
            true => Rainbow('Canary found').green,
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
        return :none unless @elf_file.segment_by_type(:gnu_relro)
        return :full if dynamic_tag(:bind_now)

        flags = dynamic_tag(:flags)
        return :full if flags && (flags.value & ::ELFTools::Constants::DF_BIND_NOW) != 0

        flags1 = dynamic_tag(:flags_1)
        return :full if flags1 && (flags1.value & ::ELFTools::Constants::DF_1_NOW) != 0

        :partial
      end

      # Is this ELF file has canary?
      #
      # Actually judged by if +__stack_chk_fail+ in got symbols.
      #
      # @return [Boolean] Yes or not.
      def canary?
        @got.respond_to?('__stack_chk_fail') || @symbols.respond_to?('__stack_chk_fail')
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
      # @return [String]
      def inspect
        "#<Pwnlib::ELF::ELF:#{::Pwnlib::Util::Fiddling.hex(__id__)}>"
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

      # Returns one-gadgets of glibc.
      #
      # @return [Array<Integer>]
      #   Returns array of one-gadgets, see examples.
      #
      # @example
      #   ELF::ELF.new('/lib/x86_64-linux-gnu/libc.so.6').one_gadgets[0]
      #   #=> 324293 # 0x4f2c5
      #
      # @example
      #   libc = ELF::ELF.new('/lib/x86_64-linux-gnu/libc.so.6')
      #   libc.one_gadgets[1]
      #   #=> 324386 # 0x4f322
      #
      #   libc.address = 0x7fff7fff0000
      #   libc.one_gadgets[1]
      #   #=> 140735341130530 # 0x7fff8003f322
      #
      # @example
      #   libc = ELF::ELF.new('/lib/x86_64-linux-gnu/libc.so.6')
      #   context.log_level = :debug
      #   libc.one_gadgets[0]
      #   # [DEBUG] 0x4f2c5 execve("/bin/sh", rsp+0x40, environ)
      #   # constraints:
      #   #   rcx == NULL
      #   #=> 324293
      def one_gadgets
        return @one_gadgets if @one_gadgets

        gadgets = OneGadget.gadgets(file: @path, details: true, level: 1)
        @one_gadgets = gadgets.map { |g| g.offset + address }
        @one_gadgets.instance_variable_set(:@gadgets, gadgets)

        class << @one_gadgets
          def [](idx)
            super.tap { log.debug(@gadgets[idx].inspect) }
          end

          def first
            self[0]
          end

          def last
            self[-1]
          end

          include ::Pwnlib::Logger
        end

        @one_gadgets
      end

      private

      def show_info(path)
        log.info(path.inspect)
        log.indented(checksec, level: ::Pwnlib::Logger::INFO)
      end

      # Get the dynamic tag with +type+.
      # @return [ELFTools::Dynamic::Tag, nil]
      def dynamic_tag(type)
        dynamic = @elf_file.segment_by_type(:dynamic) || @elf_file.section_by_name('.dynamic')
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

            @got[symbol.name] = rel.header.r_offset.to_i
          end
        end
      end

      PLT_OFFSET = 0x10 # magic offset, correct in i386/amd64.
      # Load all plt symbols.
      def load_plt
        # Unlike pwntools-python, which use unicorn emulating instructions to find plt(s).
        # Here only use section information, which won't find any plt(s) when compile option '-Wl' is enabled.
        #
        # The implementation here same as pwntools-python 3.5, and supports i386 and amd64 only.
        @plt = nil
        plt_sec = @elf_file.section_by_name('.plt')
        return log.warn('No PLT section found, PLT not loaded') if plt_sec.nil?

        rel_sec = @elf_file.section_by_name('.rel.plt') || @elf_file.section_by_name('.rela.plt')
        return log.warn('No REL.PLT section found, PLT not loaded') if rel_sec.nil?

        symtab = @elf_file.section_at(rel_sec.header.sh_link)
        return unless symtab.respond_to?(:symbol_at) # unusual case

        @plt = OpenStruct.new
        address = plt_sec.header.sh_addr.to_i + PLT_OFFSET
        rel_sec.relocations.each do |rel|
          symbol = symtab.symbol_at(rel.symbol_index)
          next if symbol.nil? # unusual case

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
            @symbols[symbol.name] = symbol.header.st_value.to_i
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

      include ::Pwnlib::Logger
    end
  end
end
