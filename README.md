# Broadcaster

[![Gem Version](https://badge.fury.io/rb/broadcaster.svg)](https://rubygems.org/gems/broadcaster)
[![Build Status](https://travis-ci.org/gabynaiman/broadcaster.svg?branch=master)](https://travis-ci.org/gabynaiman/broadcaster)
[![Coverage Status](https://coveralls.io/repos/gabynaiman/broadcaster/badge.svg?branch=master)](https://coveralls.io/r/gabynaiman/broadcaster?branch=master)
[![Code Climate](https://codeclimate.com/github/gabynaiman/broadcaster.svg)](https://codeclimate.com/github/gabynaiman/broadcaster)

Broadcasting based on Redis PubSub

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'broadcaster'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install broadcaster

## Usage

```ruby
broadcaster = Broadcaster.new

subscription_id = broadcaster.subscribe 'channel_1' do |message|
  puts message
end

broadcaster.publish 'channel_1', 'text'
broadcaster.publish 'channel_1', 1
broadcaster.publish 'channel_1', key: 'value'

broadcaster.unsubscribe subscription_id
broadcaster.unsubscribe_all
```

## Global configuration

```ruby
Broadcaster.configure do |config|
  config.logger = Logger.new '/file.log'
  config.redis_settings = 'redis://host_name:6379'
  # or
  config.redis_client = Redic::Sentinels
  config.redis_settings = hosts: [sentinel_1, sentinel_2], master_name: 'mymaster'
end
```

## Options

```ruby
options = {
  id: 'my_app',                             # Shared broadcaster for multiple processes
  redis_settings: 'redis://host_name:6379', # Custom redis connection
  logger: Logger.new('/file.log')           # Custom logger
  # or
  redis_client: Redic::Sentinels,
  redis_settings: hosts: [sentinel_1, sentinel_2], master_name: 'mymaster'
}

Broadcaster.new options
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gabynaiman/broadcaster.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

