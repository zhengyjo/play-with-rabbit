#!/usr/bin/env ruby
require 'bunny'

connection = Bunny.new(ENV["RABBITMQ_BIGWIG_RX_URL"],automatically_recover: false)
connection.start

channel = connection.create_channel
queue = channel.queue("hello_world")

# channel.prefetch(1)
# puts ' [*] Waiting for messages. To exit press CTRL+C'

begin
  queue.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
    puts " [x] Received '#{body}'"
    # imitate some work
    sleep body.count('.').to_i
    puts ' [x] Done'
    sleep 10.0
    channel.ack(delivery_info.delivery_tag)
  end
rescue Interrupt => _
  connection.close
end
