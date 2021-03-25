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
  config.reconnection_timeout = 0.001
end

class Receiver
  attr_reader :messages

  def initialize
    @messages = []
  end

  def call(message)
    messages << message
  end
end

class MockRedis

  class << self

    def start
      @running = true
      sleep 0.05
    end

    def stop
      @running = false
      Redic.new.call 'CLIENT', 'KILL', 'TYPE', 'pubsub'
      sleep 0.05
    end

    def running?
      @running.nil? ? true : @running
    end

  end

  def initialize(*args)
    @redis = Redic.new(*args)
  end

  def call!(*args)
    raise 'Redis connection error' unless self.class.running?
    @redis.call!(*args)
  end

  def client
    @redis.client
  end

end