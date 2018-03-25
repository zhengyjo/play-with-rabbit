#!/usr/bin/env ruby
require 'bunny'
require 'thread'

class FibonacciClient
  attr_accessor :call_id, :response, :lock, :condition, :connection,
                :channel, :server_queue_name, :reply_queue, :exchange

  def initialize(server_queue_name,id)
    @connection = Bunny.new(id,automatically_recover: false)
    @connection.start

    @channel = connection.create_channel
    @exchange = channel.default_exchange
    @server_queue_name = server_queue_name

    setup_reply_queue
  end

  def call(n)
    @call_id = generate_uuid

    exchange.publish(n.to_s,
                     routing_key: server_queue_name,
                     correlation_id: call_id,
                     reply_to: reply_queue.name)

    # wait for the signal to continue the execution
    lock.synchronize { condition.wait(lock) }

    response
  end

  def call2(n)
    @call_id = generate_uuid

    exchange.publish(n.to_s,
                     routing_key: server_queue_name,
                     correlation_id: call_id,
                     reply_to: reply_queue.name)

    # wait for the signal to continue the execution
    lock.synchronize { condition.wait(lock) }

    response
  end

  def stop
    channel.close
    connection.close
  end

  private

  def setup_reply_queue
    @lock = Mutex.new
    @condition = ConditionVariable.new
    that = self
    @reply_queue = channel.queue('', exclusive: true)

    reply_queue.subscribe do |_delivery_info, properties, payload|
      if properties[:correlation_id] == that.call_id
        that.response = payload

        # sends the signal to continue the execution of #call
        that.lock.synchronize { that.condition.signal }
      end
    end
  end

  def generate_uuid
    # very naive but good enough for code examples
    "#{rand}#{rand}#{rand}"
  end

end

client = FibonacciClient.new('rpc_queue',ENV["RABBITMQ_BIGWIG_RX_URL"])


#thr = Thread.new {puts ' [x] Requesting fib(30)'; response = client.call(30);puts " [.] Got #{response}";}
#thr.join
# puts ' [x] Requesting fib(30)'
# response = client.call(30)
#
# puts " [.] Got #{response}"
#count  = 0;
loop do
  puts "I am busy I can't wait"
  #count = count + 1
  thr = Thread.new {
      puts " [x] Requesting Hello"; response = client.call2(31);puts " [.] Got #{response}";
  }
  #count = 0 if count == 30
  #thr.join
  puts "I am busy I can't wait"
  sleep 5.0
end

client.stop
