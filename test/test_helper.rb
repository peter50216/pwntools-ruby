require 'rainbow'
require 'simplecov'
require 'tty/platform'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter]
)
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'
require 'minitest/unit'
require 'minitest/hell'

module MiniTest
  class Test
    def before_setup
      super
      # Default to disable coloring for easier testing.
      Rainbow.enabled = false
    end

    def linux_only(msg = 'Only tested on Linux')
      skip msg unless TTY::Platform.new.linux?
    end

    def skip_windows(msg = 'Skip on Windows')
      skip msg if TTY::Platform.new.windows?
    end

    # Methods for hooking logger,
    # require 'pwnlib/logger' before using these methods.

    def log_null(&block)
      File.open(File::NULL, 'w') { |f| log_hook(f, &block) }
    end

    def log_stdout(&block)
      log_hook($stdout, &block)
    end

    def log_hook(obj)
      old = ::Pwnlib::Logger.log.instance_variable_get(:@logdev)
      ::Pwnlib::Logger.log.instance_variable_set(:@logdev, obj)
      begin
        yield
      ensure
        ::Pwnlib::Logger.log.instance_variable_set(:@logdev, old)
      end
    end
  end
end
