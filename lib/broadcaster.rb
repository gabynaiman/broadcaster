require 'redic'
require 'class_config'
require 'logger'

class Broadcaster

  extend ClassConfig

  attr_config :redis_client, Redic
  attr_config :redis_settings, 'redis://localhost:6379'
  attr_config :logger, Logger.new(STDOUT)

  attr_reader :id

  def initialize(options={})
    @id = options.fetch(:id, SecureRandom.uuid)
    @logger = options.fetch(:logger, Broadcaster.logger)
    @redis_client = options.fetch(:redis_client, Broadcaster.redis_client)
    @publisher = @redis_client.new options.fetch(:redis_settings, Broadcaster.redis_settings)
    @subscriber = @redis_client.new options.fetch(:redis_settings, Broadcaster.redis_settings)
    @subscriptions = Hash.new { |h,k| h[k] = {} }
    @mutex = Mutex.new
    listen
  end

  def publish(channel, message)
    logger.debug(self.class) { "Published | #{scoped(channel)} | #{message}" }
    publisher.call 'PUBLISH', scoped(channel), Marshal.dump(message)
  end

  def subscribe(channel, callable=nil, &block)
    mutex.synchronize do
      SecureRandom.uuid.tap do |subscription_id|
        logger.debug(self.class) { "Subscribed | #{scoped(channel)} | #{subscription_id}" }
        subscriptions[scoped(channel)][subscription_id] = callable || block
      end
    end
  end

  def unsubscribe(subscription_id)
    mutex.synchronize do
      channel, _ = subscriptions.detect { |k,v| v.key? subscription_id }
      if channel
        logger.debug(self.class) { "Unsubscribed | #{channel} | #{subscription_id}" }
        block = subscriptions[channel].delete subscription_id
        subscriptions.delete_if { |k,v| v.empty? }
        block
      end
    end
  end

  def unsubscribe_all
    mutex.synchronize do
      logger.debug(self.class) { 'Unsubscribed all' }
      subscriptions.clear
    end
  end

  private

  attr_reader :publisher, :subscriber, :subscriptions, :mutex, :logger

  def scoped(channel)
    "#{id}:#{channel}"
  end

  def listen
    logger.debug(self.class) { 'Start listening' }
    subscriber.call 'PSUBSCRIBE', scoped('*')

    Thread.new do
      loop do
        notification = subscriber.client.read
        channel = notification[2]
        message = Marshal.load notification[3]
        logger.debug(self.class) { "Broadcasting (#{subscriptions[channel].count}) | #{channel} | #{message}" }
        subscriptions[channel].each do |subscription_id, block|
          begin
            block.call message
          rescue => ex
            logger.error(self.class) { "Failed | #{channel} | #{subscription_id} | #{message}\n#{ex.class}: #{ex.message}\n#{ex.backtrace.join("\n")}" }
          end
        end
      end
    end
  end

end