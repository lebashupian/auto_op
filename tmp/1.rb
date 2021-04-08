#!/usr/bin/env ruby
# coding: utf-8

require 'net/ssh'

Net::SSH.start( '192.168.137.225', 'root', :password => nil ) do |ssh|
p ssh.exec!('hostname')
end
