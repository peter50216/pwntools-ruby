#!/usr/bin/env ruby

require 'socket'

if ARGV.empty?
  puts "Usage #{__FILE__} port"
  exit 1
end

server = TCPServer.open('127.0.0.1', ARGV[0].to_i)

STDOUT.puts 'Start!'
STDOUT.flush

client = server.accept
s = client.gets
client.puts(s)
client.close

STDOUT.puts 'Bye!'
