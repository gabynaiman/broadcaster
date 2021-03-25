require 'redic'
require 'class_config'
require 'logger'
require 'securerandom'

class Broadcaster

  extend ClassConfig

  attr_config :redis_client, Redic
  attr_config :redis_settings, 'redis://localhost:6379'
  attr_config :logger, Logger.new(STDOUT)
  attr_config :reconnection_timeout, 10

  attr_reader :id

  def initialize(options={})
    @id = options.fetch(:id, SecureRandom.uuid)
    @logger = options.fetch(:logger, Broadcaster.logger)
    @logger_name = "Broadcaster (#{@id})"
    @redis_client = options.fetch(:redis_client, Broadcaster.redis_client)
    @redis_settings = options.fetch(:redis_settings, Broadcaster.redis_settings)
    @publisher = new_redis_connection
    @subscriptions = Hash.new { |h,k| h[k] = {} }
    @mutex = Mutex.new
    listen
  end

  def publish(channel, message)
    publisher.call! 'PUBLISH', scoped(channel), Marshal.dump(message)
    logger.debug(logger_name) { "Published | #{scoped(channel)} | #{message}" }
  end

  def subscribe(channel, callable=nil, &block)
    mutex.synchronize do
      SecureRandom.uuid.tap do |subscription_id|
        subscriptions[scoped(channel)][subscription_id] = callable || block
        logger.debug(logger_name) { "Subscribed | #{scoped(channel)} | #{subscription_id}" }
      end
    end
  end

  def unsubscribe(subscription_id)
    mutex.synchronize do
      channel, _ = subscriptions.detect { |k,v| v.key? subscription_id }
      if channel
        block = subscriptions[channel].delete subscription_id
        subscriptions.delete_if { |k,v| v.empty? }
        logger.debug(logger_name) { "Unsubscribed | #{channel} | #{subscription_id}" }
        block
      end
    end
  end

  def unsubscribe_all
    mutex.synchronize do
      logger.debug(logger_name) { 'Unsubscribed all' }
      subscriptions.clear
    end
  end

  private

  attr_reader :publisher, :subscriber, :subscriptions, :mutex, :logger, :logger_name, :redis_client, :redis_settings

  def new_redis_connection
    redis_client.new(redis_settings).tap { |redis| redis.call! 'PING' }
  end

  def scoped(channel)
    "#{id}:#{channel}"
  end

  def listen
    subscriber = new_redis_connection
    subscriber.call! 'PSUBSCRIBE', scoped('*')

    logger.info(logger_name) { 'Listener started' }

    Thread.new do
      loop do
        begin
          notification = subscriber.client.read

          channel = notification[2]
          message = Marshal.load notification[3]

          current_subscriptions = mutex.synchronize { subscriptions[channel].dup }

          logger.debug(logger_name) { "Broadcasting (#{current_subscriptions.count}) | #{channel} | #{message}" }

          current_subscriptions.each do |subscription_id, block|
            begin
              block.call message
            rescue => ex
              logger.error(logger_name) { "Failed | #{channel} | #{subscription_id} | #{message}\n#{ex.class}: #{ex.message}\n#{ex.backtrace.join("\n")}" }
            end
          end

        rescue => ex
          logger.error(logger_name) { ex }
          break
        end
      end

      logger.warn(logger_name) { 'Listener broken' }
      listen
    end

  rescue => ex
    logger.error(logger_name) { ex }
    sleep Broadcaster.reconnection_timeout

    logger.info(logger_name) { 'Listener reconnectig' }
    retry
  end

end