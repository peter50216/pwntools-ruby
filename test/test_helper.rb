require 'codeclimate-test-reporter'
require 'rainbow'
require 'simplecov'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [SimpleCov::Formatter::HTMLFormatter, CodeClimate::TestReporter::Formatter]
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
  end
end
