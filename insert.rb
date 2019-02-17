#!/usr/bin/env ruby
# coding: utf-8
require 'active_record'
ActiveRecord::Base.establish_connection(
	:adapter  => "mysql2",  
    :username => 'root',  
    :password => '',  
    :database => 'auto_op2',  
    :host     => '127.0.0.1',
    :pool     => 10_1000  #如果这个设置的过小，下面并发的函数会报错
)

class C_主机表 < ActiveRecord::Base
	self.table_name = 'hostinfo'
	self.primary_key = 'id'
end


i=10000
100.times {|x|
	x=x+i
	p x
	主机表=C_主机表.new
	主机表.ip='192.168.137.102'
	主机表.username='root'
	主机表.password='1234'
	主机表.port=x
	主机表.grp='.all.test'
	主机表.used='Y'
	主机表.save
}

exit

require 'ipaddr'
#C_数据库连接.connection.execute("delete from hostinfo;")


net1 = IPAddr.new("192.168.137.0/28")

net1.to_range.each {|ip| 
	#主机表=C_主机表.new
	p ip.to_s
=begin
	主机表.ip=ip.to_s
	主机表.username='root'
	主机表.password='wxlnote'
	主机表.port=22
	主机表.grp='all'
	主机表.used='Y'
	主机表.save
=end
}


exit

随机字符=Proc.new {|n|
	str=''.dup
	a=("a".."c").to_a
	n.times {
		str += a.sample
	}
	str
}


(41..46).each {|x|
	主机表=C_主机表.new
	主机表.ip="192.168.137.#{x}"
	主机表.username='root'
	主机表.password='wxlnote'
	主机表.port=22
	主机表.grp=随机字符.call(1)
	主机表.used='Y'
	主机表.save		
}
