require 'minitest_helper'

describe Broadcaster do

  def wait_for(&block)
    Timeout.timeout(3) do
      while !block.call
        sleep 0.001
      end
    end
  end
  
  it 'Multiple channels' do
    broadcaster = Broadcaster.new

    received_messages = Hash.new { |h,k| h[k] = [] }

    %w(channel_1 channel_2).each do |channel|
      broadcaster.subscribe channel do |message|
        received_messages[channel] << message
      end
    end

    broadcaster.publish 'channel_1', 'message 1'
    broadcaster.publish 'channel_2', 'message 2'
    broadcaster.publish 'channel_2', 'message 3'
    broadcaster.publish 'channel_1', 'message 4'

    wait_for { received_messages.values.flatten.count == 4 }

    received_messages.must_equal 'channel_1' => ['message 1', 'message 4'], 
                                 'channel_2' => ['message 2', 'message 3']
  end

  it 'Error handling' do
    broadcaster = Broadcaster.new

    received_messages = []

    broadcaster.subscribe 'channel_1' do |message|
      received_messages << (10 / message)
    end

    broadcaster.publish 'channel_1', 5
    broadcaster.publish 'channel_1', 0
    broadcaster.publish 'channel_1', 2

    wait_for { received_messages.count == 2 }

    received_messages.must_equal [2, 5]
  end

  it 'Unsubscribe' do
    broadcaster = Broadcaster.new

    received_messages = Hash.new { |h,k| h[k] = [] }

    subscriptions = 2.times.map do |i|
      broadcaster.subscribe 'channel_1' do |message|
        received_messages[i] << message 
      end
    end

    broadcaster.publish 'channel_1', 'message 1'

    wait_for { received_messages.values.flatten.count == 2 }

    broadcaster.unsubscribe subscriptions[1]

    broadcaster.publish 'channel_1', 'message 2'

    wait_for { received_messages.values.flatten.count == 3 }

    received_messages.must_equal 0 => ['message 1', 'message 2'],
                                 1 => ['message 1']
  end

  it 'Unsubscribe all' do
    broadcaster = Broadcaster.new

    received_messages = []

    2.times.map do
      broadcaster.subscribe 'channel_1' do |message|
        received_messages << message 
      end
    end

    broadcaster.publish 'channel_1', 'message 1'

    wait_for { received_messages.count == 2 }

    broadcaster.unsubscribe_all

    broadcaster.publish 'channel_1', 'message 2'

    received_messages.must_equal ['message 1', 'message 1']
  end

  it 'Isolated' do
    broadcasters = 2.times.map { Broadcaster.new }

    received_messages = Hash.new { |h,k| h[k] = [] }

    broadcasters.each_with_index do |broadcaster, index|
      broadcaster.subscribe 'channel_1' do |message|
        received_messages[index] << message
      end
    end

    broadcasters[0].publish 'channel_1', 'message 1'
    broadcasters[1].publish 'channel_1', 'message 2'

    wait_for { received_messages.values.flatten.count == 2 }

    received_messages.must_equal 0 => ['message 1'],
                                 1 => ['message 2']
  end

  it 'Shared' do
    broadcasters = 2.times.map { Broadcaster.new id: 'test' }

    received_messages = Hash.new { |h,k| h[k] = [] }

    broadcasters.each_with_index do |broadcaster, index|
      broadcaster.subscribe 'channel_1' do |message|
        received_messages[index] << message
      end
    end

    broadcasters[0].publish 'channel_1', 'message 1'
    broadcasters[1].publish 'channel_1', 'message 2'

    wait_for { received_messages.values.flatten.count == 4 }

    received_messages.must_equal 0 => ['message 1', 'message 2'],
                                 1 => ['message 1', 'message 2']
  end

  it 'Custom redis url' do
    error = proc { Broadcaster.new redis_url: 'redis://invalid_host:6379' }.must_raise StandardError
    error.message.must_match 'invalid_host'
  end

end