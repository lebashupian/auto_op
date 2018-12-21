#!/opt/ruby-2.5.1/bin/ruby -w
# coding: utf-8
require 'socket'

s1, s2 = UNIXSocket.pair
1000000.times {|x|
	s1.send "#{x**10}", 0
	p s2.recv(100000)
	sleep 0.01
}