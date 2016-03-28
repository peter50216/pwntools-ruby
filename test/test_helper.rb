require 'codeclimate-test-reporter'

require 'simplecov'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  CodeClimate::TestReporter::Formatter
]
SimpleCov.start do
  add_filter '/test/'
end

require 'minitest/autorun'
require 'minitest/unit'
