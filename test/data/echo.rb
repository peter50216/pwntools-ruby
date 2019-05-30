#!/usr/bin/env ruby
# frozen_string_literal: true

require 'socket'

server = TCPServer.open('127.0.0.1', 0)

STDOUT.puts "Start with port #{server.addr[1]}"
STDOUT.flush

client = server.accept
s = client.gets
client.puts(s)
client.close

STDOUT.puts 'Bye!'
