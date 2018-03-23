#!/usr/bin/env ruby
# encoding: utf-8

require "bunny"

STDOUT.sync = true

conn = Bunny.new(ENV["RABBITMQ_BIGWIG_RX_URL"])
conn.start

ch = conn.create_channel
q  = ch.queue("hello_world")
x  = ch.default_exchange

# q.subscribe do |delivery_info, metadata, payload|
#   puts "Received #{payload}"
# end

loop do
  x.publish("Hello!", :routing_key => q.name)
  puts "send send send"
end

sleep 1.0
conn.close
