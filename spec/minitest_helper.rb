require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]
SimpleCov.start

require 'broadcaster'
require 'minitest/autorun'
require 'minitest/colorin'
require 'pry-nav'
require 'timeout'

Broadcaster.configure do |config|
  config.logger = Logger.new '/dev/null'
end