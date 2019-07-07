#!/usr/bin/env ruby
# coding: utf-8
require 'active_record'
=begin
ActiveRecord::Base.establish_connection(
	:adapter  => "mysql2",  
    :username => 'root',  
    :password => '',  
    :database => 'auto_op2',  
    :host     => '127.0.0.1',
    :pool     => 10_1000  #如果这个设置的过小，下面并发的函数会报错
)
=end
YAML_FILE="#{__dir__}/config/doauto.yml"
$配置文件=YAML.load(File.open(YAML_FILE,'r'));
#p $配置文件["config"]["sshlog"]
################
# 数据库连接
################
db_select=$配置文件["database"]["db_select"]
db_adapter=$配置文件["database"]["db_adapter"]
db_host=$配置文件["database"]["db_host"]
db_user=$配置文件["database"]["db_user"]
db_schema=  $配置文件["database"]["db_schema"]
db_pwd= $配置文件["database"]["db_pwd"]

sqlite_adapter=$配置文件["database"]["sqlite_adapter"]
sqlite_database=$配置文件["database"]["sqlite_database"]
sqlite_pool=$配置文件["database"]["sqlite_pool"]
sqlite_timeout=$配置文件["database"]["sqlite_timeout"]
if db_select == 'mysql'
	ActiveRecord::Base.establish_connection(
		:adapter  => db_adapter,  
	    :username => db_user,  
	    :password => db_pwd,  
	    :database => db_schema,  
	    :host     => db_host,
	    :pool     => 10_0000  #如果这个设置的过小，下面并发的函数会报错
	)
elsif  db_select == 'sqlite3'
	ActiveRecord::Base.establish_connection(
		:adapter  => sqlite_adapter,   
	    :database => sqlite_database,  
	    :pool     => sqlite_pool #如果这个设置的过小，下面并发的函数会报错
	)
end

class C_主机表 < ActiveRecord::Base
	self.table_name = 'hostinfo'
	self.primary_key = 'id'
end


#
# demo，添加本地主机为远程主机。主要用于基本测试
#

200.times {|x|
	x += 1
	ip='127.0.0.' + x.to_s
        主机表=C_主机表.new
        主机表.ip=ip
        主机表.username='ceshi'
        主机表.password='1234'
        主机表.port=22
        主机表.grp='.all.test'
        主机表.used='Y'
        主机表.save
}
puts "主机添加完成，你需要在添加一个用户ceshi,密码是1234,测试完成之后，请删除本地用户"

exit


#
# 范例1，批量添加连续ip主机到数据库
#

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

#
# 范例2，添加不连续ip主机到数据库
# 比如 192.168.137.18-45 和 192.168.137.66 192.168.137.68


主机数组=[]

#
# 定义一个范围
#
(18..45).each {|x|
	ip = "192.168.137." + x.to_s
	主机数组 << ip 
}

主机数组 << '192.168.137.66'
主机数组 << '192.168.137.68'

主机数组.each {|ip地址|
	主机表=C_主机表.new
	主机表.ip=ip地址
	主机表.username='root'
	主机表.password='1234'
	主机表.port=22
	主机表.grp='.all.test'
	主机表.used='Y'
	主机表.save	
}

