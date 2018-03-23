#!/usr/bin/env ruby
require 'bunny'

class FibonacciServer
  def initialize(id)
    @connection = Bunny.new(id)
    @connection.start
    @channel = @connection.create_channel
  end

  def start(queue_name)
    @queue = channel.queue(queue_name)
    @exchange = channel.default_exchange
    subscribe_to_queue
  end

  def stop
    channel.close
    connection.close
  end

  private

  attr_reader :channel, :exchange, :queue, :connection

  def subscribe_to_queue
    queue.subscribe(block: true) do |_delivery_info, properties, payload|
      puts "[x] Get message #{payload.to_i}. Gonna caculate the fibonacci of #{payload.to_i}"
      result = fibonacci(payload.to_i)


      exchange.publish(
        result.to_s,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def fibonacci(value)
    return value if value.zero? || value == 1

    fibonacci(value - 1) + fibonacci(value - 2)
  end
end

begin
  server = FibonacciServer.new(ENV["RABBITMQ_BIGWIG_RX_URL"])

  puts ' [x] Awaiting RPC requests'
  server.start('rpc_queue')
rescue Interrupt => _
  server.stop
end
