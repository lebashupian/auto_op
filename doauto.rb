#!/usr/bin/env ruby
# coding: utf-8

begin  #所有程序都放在一个测试块中，来捕捉Ctrl-C

require_relative "basic_funcion"

################
# 命令提示符判断
# 先判断是否有参数
M_基础方法.退出信息("没有指定参数,你可以先使用--help查看一下帮助内容") if ARGV[0] == nil

# 判断是否是需要help
(M_常量::CONS_帮助信息.each_line {|x| puts x};exit 2;) if ARGV.include? "--help"





#######################################################
# 脚本参数处理
#######################################################
# 首先设置默认值
$脚本参数hash表={}
# 使用脚本的参数赋值重新覆盖默认参数
ARGV.each {|x|
  $脚本参数hash表.merge!({"#{x.split("=")[0]}" => "#{x.split("=")[1]}"});
}


# 判断是否给与了cmd命令参数，以及参数的子参数是否正确

def 有?(参数)
	return $脚本参数hash表.has_key?(参数)
end

alias 参数有? 有? 

def 没有?(参数)
	return !$脚本参数hash表.has_key?(参数)
end

def a在b其中?(a,b)
	return b.split(' ').include?(a)
end

def 等于?(a,b)
	return $脚本参数hash表[a]==b
end

def 有值?(a)
	return  $脚本参数hash表[a] != ""
end

def 没有值?(a)
	return  $脚本参数hash表[a] == ""
end

def k或v缺失?(a)
	return (!$脚本参数hash表.has_key?(a) or $脚本参数hash表[a] == "")
end

p $脚本参数hash表 if 参数有? "--debug"

M_基础方法.退出信息("你需要指定--behavior参数") if 没有? "--behavior"

if 有? "--behavior" and !(a在b其中? $脚本参数hash表["--behavior"],'x scp cs info greplog dbinit console')
	M_基础方法.退出信息("--behavior参数的可选值有 x scp cs info greplog dbinit") 
end

if 等于? "--behavior","x" and ( ( 没有? "--script" and 没有? "--cmd" ) or ( 有? "--script" and 没有值? "--script" ) or ( 有? "--cmd" and 没有值? "--cmd" ) ) 
	M_基础方法.退出信息("必须指定--script=xxx或--cmd=xxx") 
end

if 等于? "--behavior","x" and ( 没有? "--host" or ( 有? "--host" and 没有值? "--host" ) )
	M_基础方法.退出信息("必须指定--host=xxx")
end

if 等于? "--behavior","scp" and ( k或v缺失? "--local" or k或v缺失? "--remote" or k或v缺失? "--direction" or k或v缺失? "--host")
	M_基础方法.退出信息("必须指定--host=xxx --local=xxx --remote=xxx --direction=push|pull")
end

if 等于? "--behavior","greplog" and ( k或v缺失? "--host" or k或v缺失? "--logfile" or 没有? "--grepword" or k或v缺失? "--regex")
	M_基础方法.退出信息("必须指定--host=xxx --logfile=xxx --grepword=xxx --regex=xxx")
end

################
# 命令内容 注意，不要使用交互式的命令，否则程序会处于一直等待的状态！！
if $脚本参数hash表["--behavior"]=='x' and $脚本参数hash表.has_key?("--cmd")
	$命令信息,$命令类型=$脚本参数hash表["--cmd"],"cmd"
elsif $脚本参数hash表["--behavior"]=='x' and $脚本参数hash表.has_key?("--script")
	$命令信息,$命令类型=$脚本参数hash表["--script"],"script"
end
################
# 传输文件
if $脚本参数hash表["--behavior"]=='scp'
	$传输文件={};
	$传输文件["本地文件"]=$脚本参数hash表["--local"]
	$传输文件["远程文件"]=$脚本参数hash表["--remote"]
	$传输文件["动作"]    ="未知动作"
	$传输文件["动作"]    ="上载" if $脚本参数hash表["--direction"]=='push'
	$传输文件["动作"]    ="下载" if $脚本参数hash表["--direction"]=='pull'
end

################
# 正则分析日志
if $脚本参数hash表["--behavior"]=='greplog'
	$正则参数={};
	$正则参数["日志文件名"]=$脚本参数hash表["--logfile"];
	$正则参数["grep字符串"]=$脚本参数hash表["--grepword"];
	$正则参数["正则表达式"]=$脚本参数hash表["--regex"];	
end

##################
# 控制台交互





#####################################################################################################
#                                             配置部分
#####################################################################################################
#                
#####################################################################################################
#####################################################################################################
YAML_FILE="#{__dir__}/config/doauto.yml"
$配置文件=YAML.load(File.open(YAML_FILE,'r'));
#p $配置文件["config"]["sshlog"]
################
# 数据库连接
################
db_host=$配置文件["database"]["db_host"]
db_user=$配置文件["database"]["db_user"]
db_schema=  $配置文件["database"]["db_schema"]
db_pwd= $配置文件["database"]["db_pwd"]


ActiveRecord::Base.establish_connection(
	:adapter  => "mysql2",  
    :username => db_user,  
    :password => db_pwd,  
    :database => db_schema,  
    :host     => db_host,
    :pool     => 10_1000  #如果这个设置的过小，下面并发的函数会报错
)

class C_数据库连接 < ActiveRecord::Base
end

class C_主机表 < ActiveRecord::Base
	self.table_name = 'hostinfo'
	self.primary_key = 'id'
end

class C_运行表 < ActiveRecord::Base
	self.table_name = 'run_log'
	self.primary_key = 'id'
end

C_数据库连接.connection.execute("delete from run_log;")
C_数据库连接.connection.execute("commit;")



################
# 标准$输出对象
################
$输出对象=Output.new

#########################
# 首次初始化数据库
#########################
class C_数据库结构 < ActiveRecord::Migration[5.2]
	def 新建
	    create_table :hostinfo do |t|
	    #默认会创建id字段,并作为主键	
	    t.string :ip , null: false
	    t.string :username , null: false
	    t.string :password , null: true
	    t.integer :port , null: false, default: 22, comment: "端口"
	    t.string :grp , null: false,comment: "匹配字段"
	    t.string :used ,null: false,default: "Y",comment: "是否可用"
	    end

	    create_table :run_log do |t|
	    	t.string :ip,null: true
	    	t.string :port,null: true
	    	t.string :status,null: true
	    	t.datetime :start_time
	    	t.datetime :end_time
	    end	
	end
	def 删除
		begin
			drop_table :hostinfo
			drop_table :run_log
		rescue Exception => e
			nil
		end
	end
end
def 初始化数据库结构
	C_数据库结构.new.删除
	C_数据库结构.new.新建
	puts "初始化完成"
	exit
end
初始化数据库结构 if $脚本参数hash表["--behavior"]=='dbinit'


=begin
require 'ipaddr'
C_数据库连接.connection.execute("delete from hostinfo;")


net1 = IPAddr.new("192.168.137.0/28")

net1.to_range.each {|ip| 
	主机表=C_主机表.new
	p ip.to_s
	主机表.ip=ip.to_s
	主机表.username='root'
	主机表.password='wxlnote'
	主机表.port=22
	主机表.grp='all'
	主机表.used='Y'
	主机表.save	
}


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
=end

class C_自动化操作
	attr_accessor :主机grep,:配置文件
	def initialize()
		@主机grep =$脚本参数hash表["--host"]
		@配置文件=$配置文件
		@输出对象=Output.new
	end

	def 查询主机信息(主机匹配=nil)
		主机信息=C_主机表.where(%Q[grp like '#{主机匹配}%']);
		# 设置默认行长,然后针对每个字段遍历行的长度,
		# 一旦发现有比现在的行更长的,
		# 将显示的列宽修改为当前行的行长
		
		ip_行长,username_行长,grp_行长,used_行长=0,0,0,0
		主机信息.each {|行| 
			ip_行长       = 行.ip.size       if ip_行长       < 行.ip.size 
			username_行长 = 行.username.size if username_行长 < 行.username.size
			grp_行长      = 行.grp.size      if grp_行长      < 行.grp.size
			used_行长     = 行.used.size     if used_行长     < 行.used.size
		};
		
		puts "用户@IP地址 | 主机类型(操作匹配字符串)|可用状态"
		主机信息.each {|主机行|
			主机ip,用户名,密码,端口,类型,可用=主机行.ip,主机行.username,主机行.password,主机行.port,主机行.grp,主机行.used
			
			puts "#{用户名}#{M_基础方法.打印空格(username_行长-用户名.size)}" + 
				 "@#{主机ip}#{M_基础方法.打印空格(ip_行长-主机ip.size)}" + 
				 "|#{类型}#{M_基础方法.打印空格(grp_行长-类型.size)}"  +
				 " |     #{可用}"
		}
	end

	def 测试主机链接(匹配=nil)
		主机信息=C_主机表.where(%Q[grp like '#{匹配}%']);
		M_基础方法.退出信息("没有匹配到任何主机") if 主机信息.count == 0
		进度条 = ProgressBar.new 主机信息.count;
		主机信息.each {|主机行|
			主机ip,用户名,密码,端口=主机行.ip,主机行.username,主机行.password,主机行.port
			begin 
				Net::SSH.start(主机ip,用户名,:port => 端口 , :password => 密码) do |ssh|
					  输出命令 = ssh.exec!("
					  	date > /dev/null 2>>/dev/shm/ssh.rb.error.log && echo #{主机ip}'连接成功' || echo #{主机ip}'连接成功,但命令执行失败';
					  ")
					  输出队列=@输出对象.生成一个队列
					  输出命令.each_line {|行|
					  	输出队列 << 行
					  }
				end
				进度条.increment!
			rescue  => 错误信息
				puts "#{主机ip}"+"连接不成功 "+"#{错误信息}"
			ensure
				nil
			end		
		}
		@输出对象.读取_所有_队列(@配置文件["config"]["sshlog"])
		@输出对象.清空队列
	end

	def 远端执行命令(主机ip参数,用户名参数,密码参数,端口参数,输出队列参数)
		begin
			Net::SSH.start(主机ip参数,用户名参数,:port => 端口参数 , :password => 密码参数) do |ssh|
					运行记录=C_运行表.new
					运行记录.ip=主机ip参数
					运行记录.port=端口参数
					运行记录.status='start'
					运行记录.start_time=Time.new.to_s.byteslice(0,19)
					运行记录.save

					if $命令类型 == 'cmd'
				  		输出命令 = ssh.exec!($命令信息)
					elsif $命令类型 == 'script'

						M_基础方法.退出信息("#{$命令信息}脚本文件不存在") if !File.file?($命令信息)
						脚本文件=File.open($命令信息,"r");
						脚本文件行数 = 0;脚本文件.each_line {|x|  脚本文件行数 += 1 };脚本文件.rewind
						脚本文件.each_line {|行|
							输出命令 ||= ''
							输出命令 << ssh.exec!("#{行}")
						}
						
					else
						M_基础方法.退出信息("无效的命令类型,请检查你的参数")
					end

				  	输出命令.each_line {|行|
				  		输出队列参数 << "@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + 行
				  	}
				  	sleep 1

					运行记录.status='end'
					运行记录.end_time=Time.new.to_s.byteslice(0,19)
					运行记录.save		
			end
		rescue  => 错误信息 #因为是并发的连接，可能会获取多行错误信息
			puts "#{错误信息}"
		ensure
			#exit 102
		end
	end

	def 并发执行
		################
		# 并发执行
		################

		线程数组=[];
		线程数组_计数=0;

		主机信息=C_主机表.where(%Q[grp like '#{@主机grep}%']);
		M_基础方法.退出信息("没有匹配到任何主机") if 主机信息.count == 0

		线程并发_总数=@配置文件["config"]["thread_concurrency"].to_i
		线程并发_轮次计数=1;

		线程并发_轮次最大=(主机信息.count.to_f/线程并发_总数.to_f).ceil;

		线程并发_最末轮次_计数=主机信息.count % 线程并发_总数
		进度条 = ProgressBar.new(主机信息.count);

		C_主机表.where(%Q[grp like '#{@主机grep}%']).each {|主机行|
			主机ip,用户名,密码,端口=主机行.ip,主机行.username,主机行.password,主机行.port
			线程数组 <<	Thread.new {
			 				#远端传输文件(主机ip,用户名,密码,端口,$输出对象.生成一个队列,$传输文件["本地文件"],$传输文件["远程文件"],$传输文件["动作"]) if $脚本参数hash表["--behavior"] == 'scp'
							远端执行命令(主机ip,用户名,密码,端口,@输出对象.生成一个队列) if $脚本参数hash表["--behavior"] == "x"
							#正则分析日志(主机ip,用户名,密码,端口,$输出对象.生成一个队列,$正则参数["日志文件名"],$正则参数["grep字符串"],$正则参数["正则表达式"]) if $脚本参数hash表["--behavior"] == 'greplog'
						}
			线程数组_计数 += 1;
			
			if    线程并发_轮次计数 <= 线程并发_轮次最大 && 线程数组_计数 == 线程并发_总数
					线程数组.each {|x|	x.join } && 线程数组_计数=0;
					线程并发_轮次计数 += 1;
			elsif 线程并发_轮次计数 == 线程并发_轮次最大 && 线程数组_计数 == 线程并发_最末轮次_计数
					线程数组.each {|x|	x.join } && 线程数组_计数=0;
					线程并发_轮次计数 += 1;
			end

			进度条.increment!
		}

		@输出对象.读取_所有_队列(@配置文件["config"]["sshlog"])
		@输出对象.清空队列
	end
end





(C_自动化操作.new.查询主机信息 if $脚本参数hash表["--behavior"]=='info') && exit;
(C_自动化操作.new.测试主机链接 if $脚本参数hash表["--behavior"]=='cs')  && exit;


C_自动化操作.new.并发执行 if $脚本参数hash表["--behavior"]=='x'

if $脚本参数hash表["--behavior"]=='console'
	$实例=C_自动化操作.new
	def show(主机匹配=nil)
		$实例.查询主机信息 主机匹配
	end
	def cs(主机匹配=nil)
		$实例.测试主机链接 主机匹配
	end

	def x(命令=nil,主机匹配=nil)

		$命令信息,$命令类型=命令,"cmd"
		$实例.主机grep = 主机匹配
		$脚本参数hash表["--behavior"] = "x"
		$实例.并发执行
	end
	C_控制台.new.开启
end 

=begin
def 正则分析日志(主机ip参数,用户名参数,密码参数,端口参数,输出队列参数,日志文件,grep过滤,正则表达式参数)
	
	begin
		cmd="#{主机ip参数} " + "#{日志文件} " + "#{grep过滤} " + "#{正则表达式参数}"
		`
			echo "#{cmd}"  >> /var/log/doauto.cmd.log;

		`
		Net::SSH.start(主机ip参数,用户名参数,:port => 端口参数 , :password => 密码参数) do |ssh|
			  日志输出 = ssh.exec!("grep \"#{grep过滤}\" #{日志文件}") if grep过滤 != ''
			  日志输出 = ssh.exec!("cat #{日志文件}") if grep过滤 == ''
			  
			  日志行数 = 0;日志输出.each_line {|x|  日志行数 += 1 }
			  进度条 = ProgressBar.new(日志行数);

			  日志输出.each_line {|行|
			  	  if Regexp.new(正则表达式参数).match(行)
			  	  	输出队列参数 <<	"@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + Regexp.new(正则表达式参数).match(行).to_s 
			  	  end
			  	  进度条.increment!
			  }
		end
	rescue  => 错误信息 #因为是并发的连接，可能会获取多行错误信息
		puts "#{错误信息}"
	ensure
		#exit 102
	end
end
=end 



=begin
def 远端传输文件(主机ip参数,用户名参数,密码参数,端口参数,输出队列参数,本地文件参数,远程文件参数,动作)
	begin 
		当前时间=Time.new.to_s.byteslice(0,19)
		输出队列参数 << "#{当前时间} #{主机ip参数} 开始连接"

	 	Net::SCP.start(主机ip参数,用户名参数,:port => 端口参数 ,:password => 密码参数) do |scp|
			if 动作 == "上载"
				# 并发上载
				上载通道数组=Array.new
				上载通道数组[0]=scp.upload(本地文件参数,远程文件参数)
				上载通道数组.each { |通道|
				通道.wait
			  	}
	 		elsif 动作 == "下载"
				# 并发下载
				下载通道数组=Array.new
				下载通道数组[0]=scp.download(远程文件参数,本地文件参数)
				下载通道数组.each { |通道|
				通道.wait 
			  	}
			else
			  puts "scp的行为未知"
			end
		end
		当前时间=Time.new.to_s.byteslice(0,19)
		输出队列参数 << "#{当前时间} #{主机ip参数} 完成操作"
	rescue  => 错误信息
		puts "#{错误信息}"
	ensure
		#exit 103
	end	
end
=end




#来捕捉Ctrl-C
rescue Interrupt
	puts "强制中断"
end


