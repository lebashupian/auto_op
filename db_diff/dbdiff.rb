#!/opt/ruby_2.2.3/bin/ruby
# coding: utf-8

require "mysql"
require 'yaml'

if ARGV[0] == '' || ARGV[0] == 'help'
	puts "1 => 比较库中的表"
	puts "2 => 比较库中的表结构"
	exit
elsif ARGV[0] == '1' || ARGV[0] == '2'
	nil  #什么都不做，继续往下执行代码
else
	puts "#{ARGV[0]}参数不支持，请输入help查看帮助"
	exit
end

YAML_FILE="#{__dir__}/../config/dbdiff.yml"
配置文件=YAML.load(File.open(YAML_FILE,'r'));

主机1={
	:IP地址  => 配置文件["database1"]["db_host"],
	:用户    => 配置文件["database1"]["db_user"],
	:密码    => 配置文件["database1"]["db_pwd"],
	:数据库  => 配置文件["database1"]["db_schema"]
}
主机2={
	:IP地址  => 配置文件["database2"]["db_host"],
	:用户    => 配置文件["database2"]["db_user"],
	:密码    => 配置文件["database2"]["db_pwd"],
	:数据库  => 配置文件["database2"]["db_schema"]
}

def 比较库(主机1,主机2)

	主机1_数据库_实例=Mysql::new(主机1[:IP地址],主机1[:用户],主机1[:密码],主机1[:数据库])
	主机2_数据库_实例=Mysql::new(主机2[:IP地址],主机2[:用户],主机2[:密码],主机2[:数据库])
	查询结果1=主机1_数据库_实例.query("SET NAMES 'utf8'");
	查询结果2=主机2_数据库_实例.query("SET NAMES 'utf8'");
	sql_1=%Q{
		select 
			TABLE_NAME 
		from 
			information_schema.TABLES
		where 
			TABLE_SCHEMA='#{主机1[:数据库]}' 
			order by TABLE_NAME desc;
	}
	sql_2=%Q{
		select 
			TABLE_NAME 
		from 
			information_schema.TABLES
		where 
			TABLE_SCHEMA='#{主机2[:数据库]}' 
			order by TABLE_NAME desc;
	}

	查询结果1=主机1_数据库_实例.query(sql_1);
	查询结果2=主机2_数据库_实例.query(sql_2);

	表数组1=[];查询结果1.each{|x| 表数组1 << x };查询结果1.data_seek(0);
	表数组2=[];查询结果2.each{|x| 表数组2 << x };查询结果1.data_seek(0);

	合并数组=表数组1|表数组2

	puts "----------------------------------------------------------------"
	print %Q|#{(主机1[:数据库]+"@"+主机1[:IP地址]).center(20)}|;print " <主机> "
	print %Q|#{(主机2[:数据库]+"@"+主机2[:IP地址]).center(20)}|;print "\n"
	puts "----------------------------------------------------------------"
	(合并数组-表数组1).each {|x|
		puts "#{sprintf("%-20s",x[0].to_s)} <=表=> #{sprintf("%-20s",'')}"
	}
	(合并数组-表数组2).each {|x|
		puts "#{sprintf("%-20s",'')} <=表=> #{sprintf("%-20s",x[0].to_s)}"
	}

	主机1_数据库_实例.close;主机2_数据库_实例.close

end

比较库(主机1,主机2) if ARGV[0]=='1'

def 比较表(主机1,主机2) 
	
	主机1_数据库_实例=Mysql::new(主机1[:IP地址],主机1[:用户],主机1[:密码],主机1[:数据库])
	主机2_数据库_实例=Mysql::new(主机2[:IP地址],主机2[:用户],主机2[:密码],主机2[:数据库])
	查询结果1=主机1_数据库_实例.query("SET NAMES 'utf8'");
	查询结果2=主机2_数据库_实例.query("SET NAMES 'utf8'");
	sql_1=%Q{
		select 
			TABLE_NAME,COLUMN_NAME 
		from 
			information_schema.COLUMNS
		where 
			TABLE_SCHEMA='#{主机1[:数据库]}' 
			order by TABLE_NAME desc;
	}
	sql_2=%Q{
		select 
			TABLE_NAME,COLUMN_NAME 
		from 
			information_schema.COLUMNS
		where 
			TABLE_SCHEMA='#{主机2[:数据库]}' 
			order by TABLE_NAME desc;
	}	

	查询结果1=主机1_数据库_实例.query(sql_1);
	查询结果2=主机2_数据库_实例.query(sql_2);

	表数组1=[];查询结果1.each{|x| 表数组1 << x };查询结果1.data_seek(0);
	表数组2=[];查询结果2.each{|x| 表数组2 << x };查询结果1.data_seek(0);

	合并数组=表数组1|表数组2
	puts "----------------------------------------------------------------"
	print %Q|#{(主机1[:数据库]+"@"+主机1[:IP地址]).center(20)}|;print " <主机> "
	print %Q|#{(主机2[:数据库]+"@"+主机2[:IP地址]).center(20)}|;print "\n"
	puts "----------------------------------------------------------------"
	
	##########################
	#注意！  合并数组-表数组2 == > 主机1多出来的
	##########################
	(合并数组-表数组2).each {|x|
		puts "#{sprintf("%-20s",(x[0]+" : "+x[1]).force_encoding(Encoding::UTF_8))} <=表=> #{sprintf("%-20s",'')}"
	}
	##########################
	#注意！  合并数组-表数组1 == > 主机2多出来的
	##########################
	(合并数组-表数组1).each {|x|
		puts "#{sprintf("%-20s",'')} <=表=> #{sprintf("%-20s",(x[0]+" : "+x[1]).force_encoding(Encoding::UTF_8))}"
	}
	主机1_数据库_实例.close;主机2_数据库_实例.close
end

比较表(主机1,主机2) if ARGV[0]=='2'
