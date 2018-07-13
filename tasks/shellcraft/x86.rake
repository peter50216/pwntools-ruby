namespace :shellcraft do
  # Example: bundle exec rake 'shellcraft:x86[linux/*.rb]'
  desc 'Generate the almost same files under amd64/i386 that invoke methods of X86'
  GEN_PATH = File.join(__dir__, '..', '..', 'lib', 'pwnlib', 'shellcraft', 'generators').freeze
  task :x86, :pattern do |_t, args|
    pattern = File.join(GEN_PATH, 'x86', args.pattern)

    Dir.glob(pattern).each do |path|
      do_gen(Pathname.new(path).relative_path_from(Pathname.new(GEN_PATH)).to_s)
    end
  end

  TEMPLATE = <<-EOS.freeze
# encoding: ASCII-8BIT

require 'pwnlib/shellcraft/generators/%<arch>s/%<dir>s/%<dir>s'
require 'pwnlib/shellcraft/generators/x86/%<dir>s/%<func>s'

module Pwnlib
  module Shellcraft
    module Generators
      module %<Arch>s
        module %<Dir>s
          # @overload %<prototype>s
          #
          # @see Generators::X86::%<Dir>s#%<func>s
          def %<func>s(*args)
            context.local(arch: :%<arch>s) do
              cat X86::%<Dir>s.%<func>s(*args)
            end
          end
        end
      end
    end
  end
end
  EOS

  def do_gen(path)
    x86, dir, file = path.split('/')
    invalid(path) unless x86 == 'x86' && %w[linux common].include?(dir) && file.end_with?('.rb')
    func = file[0..-4]
    return if dir == func
    puts "Generating files of #{path.inspect}.."
    dir_ = dir.capitalize
    prototype = IO.binread(File.join(GEN_PATH, path)).scan(/^\s+def (#{func}.*)$/).flatten.last
    %w[amd64 i386].each do |arch|
      arch_ = arch.capitalize
      str = format(TEMPLATE,
                   arch: arch, Arch: arch_,
                   func: func, prototype: prototype,
                   dir: dir, Dir: dir_)
      IO.binwrite(File.join(GEN_PATH, arch, dir, file), str)
    end
  end

  def invalid(path)
    raise ArgumentError, "Invalid path: #{path.inspect}."
  end
end
