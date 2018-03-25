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

  # def start(queue_name)
  #   @queue2 = channel.queue(queue_name)
  #   @exchange2 = channel.default_exchange
  #   subscribe_to_queue2
  # end

  def stop
    channel.close
    connection.close
  end

  private

  attr_reader :channel, :exchange, :queue, :connection, :exchange2, :queue2

  def subscribe_to_queue
    queue.subscribe(block: true) do |_delivery_info, properties, payload|
      puts "[x] Get message #{payload}. Gonna caculate the fibonacci of #{payload}"
      result = payload.to_i
      puts result < 30
      if (payload.to_i < 30)
        result = fibonacci(payload.to_i)
        result = result.to_s
      else
        result = sayHello(payload.to_i)
      end

      puts result
      puts result.class



      exchange.publish(
        result,
        routing_key: properties.reply_to,
        correlation_id: properties.correlation_id
      )
    end
  end

  def subscribe_to_queue2
    queue2.subscribe(block: true) do |_delivery_info, properties, payload|
      puts "[x] Get message #{payload.to_i}. Gonna Say hello to #{payload.to_i}"
      result = sayHello(payload.to_i)


      exchange2.publish(
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

  def sayHello(value)
    return "Hello + #{value.to_s}"
  end

  def is_numeric(o)
    true if Integer(o) rescue false
  end
end

begin
  server = FibonacciServer.new(ENV["RABBITMQ_BIGWIG_RX_URL"])

  puts ' [x] Awaiting RPC requests'
  server.start('rpc_queue')
  #server.start2('rpc_queue_hello')
rescue Interrupt => _
  server.stop
end
