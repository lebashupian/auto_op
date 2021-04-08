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
allhost=C_主机表.all()

allhost.each {|host|
	host.port='9033'
	host.port='3333' if host.ip=='127.0.0.1'
	host.grp='.all.db' if host.ip=='127.0.0.2'
	host.save
}
puts "主机添加完成，你需要在添加一个用户ceshi,密码是1234,测试完成之后，请删除本地用户"
