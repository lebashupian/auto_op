#!/usr/bin/env ruby
# coding: utf-8

begin  #所有程序都放在一个测试块中，来捕捉Ctrl-C

require_relative "basic_funcion"

#
# 这部分异常处理，主要是为了兼容脚本里面调用doauto，因为无法正常输出进度条而导致的报错
#
begin
	require "wxl_process_bar"
rescue Exception => e
	nil
end


################
# 命令提示符判断
# 先判断是否有参数
# # 判断是否是需要help
(M_常量::CONS_帮助信息.each_line {|x| puts x};exit 2;) if ARGV[0] == nil or ARGV.include? "--help"




(M_常量::CONS_FAQ.each_line {|x| puts x};exit 2;) if ARGV.include? "--faq"



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

#
# 让命令行支持 -B选项
#
if 有? "-B"
	$脚本参数hash表["--behavior"]=$脚本参数hash表["-B"]
end 

M_基础方法.退出信息("你需要指定--behavior参数") if 没有? "--behavior"

if 有? "--behavior" and !(a在b其中? $脚本参数hash表["--behavior"],'x test info dbinit console chpasswd checkenv push pull')
	M_基础方法.退出信息("--behavior参数的可选值有 x test info dbinit console chpasswd checkenv ") 
end

if 等于? "--behavior","x" and ( ( 没有? "--script" and 没有? "--cmd" ) or ( 有? "--script" and 没有值? "--script" ) or ( 有? "--cmd" and 没有值? "--cmd" ) ) 
	M_基础方法.退出信息("必须指定--script=xxx或--cmd=xxx") 
end

if 等于? "--behavior","x" and ( 没有? "--host" or ( 有? "--host" and 没有值? "--host" ) )
	M_基础方法.退出信息("必须指定--host=xxx")
end



################
# 命令内容 注意，不要使用交互式的命令，否则程序会处于一直等待的状态！！
if $脚本参数hash表["--behavior"]=='x' and $脚本参数hash表.has_key?("--cmd")
	$命令信息,$命令类型=$脚本参数hash表["--cmd"],"cmd"
elsif $脚本参数hash表["--behavior"]=='x' and $脚本参数hash表.has_key?("--script")
	$命令信息,$命令类型=$脚本参数hash表["--script"],"script"
end




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


C_数据库连接.connection.execute("delete from run_log;")
C_数据库连接.connection.execute("commit;")



class C_自动化操作
	attr_accessor :主机grep,:配置文件
	def initialize()
		@主机grep =$脚本参数hash表["--host"]
		@配置文件=$配置文件
		@输出对象=Output.new
		if $脚本参数hash表["--local"] != nil
			@本地路径 = $脚本参数hash表["--local"]
		end
		if $脚本参数hash表["--remote"] != nil
			@远程路径 = $脚本参数hash表["--remote"]
		end
	end

	def 查询主机信息(主机匹配=nil)
		主机匹配 ||= $脚本参数hash表["--host"]
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


	def 推送文件到远端(主机ip参数,用户名参数,密码参数,端口参数,本地路径参数,远程路径参数,输出队列参数)
		Net::SFTP.start(主机ip参数, 用户名参数, :password => 密码参数,:port => 端口参数) do |sftp|
			begin
				sftp.upload! 本地路径参数 , 远程路径参数
				输出队列参数 << "@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + "上载完成"
			rescue Exception => e
				#puts e.message
				输出队列参数 << "@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + e.message
			end
			
		end
	end

	def 拉取文件到本地(主机ip参数,用户名参数,密码参数,端口参数,本地路径参数,远程路径参数,输出队列参数)
		Net::SFTP.start(主机ip参数, 用户名参数, :password => 密码参数,:port => 端口参数) do |sftp|
			begin
				sftp.download! 远程路径参数 , 本地路径参数 + '/' + 主机ip参数 + 用户名参数 + 端口参数.to_s
				输出队列参数 << "@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + "下载完成"
			rescue Exception => e
				输出队列参数 << "@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + e.message
			end
			
		end		
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
						if $脚本参数hash表["--dryrun"] == "on"
							输出命令 = '执行流程测试'
						else
							输出命令 = ssh.exec!($命令信息)
							ssh.exec!($命令信息)
						end
				  		
					elsif $命令类型 == 'script'

						M_基础方法.退出信息("#{$命令信息}脚本文件不存在") if !File.file?($命令信息)
						脚本文件=File.open($命令信息,"r");
						代码块=脚本文件.read
						脚本文件.close
						
						if $脚本参数hash表["--dryrun"] == "on"
							输出命令 = '执行流程测试'
						else
							输出命令 = ssh.exec!(代码块)
						end
						
					else
						p $命令类型
						M_基础方法.退出信息("无效的命令类型,请检查你的参数")
					end

				  	输出命令.each_line {|行|
				  		输出队列参数 << "@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + 行.strip
				  	}
				  	#sleep 1

					运行记录.status='end'
					运行记录.end_time=Time.new.to_s.byteslice(0,19)
					运行记录.save		
			end
		rescue  => 错误信息 #因为是并发的连接，可能会获取多行错误信息
					输出队列参数 << "@主机" + " #{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " +"#{错误信息}"
		ensure
			#exit 102
		end
	end

	def 生成随机密码(密码长度=20)
		密码=''.dup
		全部数字=(0..9).to_a
		小写字母=('a'..'z').to_a
		大写字母=("A".."Z").to_a
		随机空间=全部数字+小写字母+大写字母
		密码长度.times {
			密码 = 密码 + 随机空间.sample.to_s
		}
		密码
	end

	def 修改密码
		主机信息=C_主机表.where(%Q[grp like '#{@主机grep}%']);
		进度条2=C_进度条.new 主机信息.count
		C_主机表.where(%Q[grp like '#{@主机grep}%']).each {|主机行|				
			主机ip,用户名,密码,端口=主机行.ip,主机行.username,主机行.password,主机行.port

			新密码=生成随机密码
			$命令类型='cmd'
			$命令信息="echo #{新密码}|passwd --stdin #{主机行.username}"
			
			远端执行命令(主机ip,用户名,密码,端口,@输出对象.生成一个队列)
			主机行.password=新密码
			主机行.save

			进度条2.更新
		}
	end

	def 检查环境
		if a在b其中? RUBY_PLATFORM,'x86_64-linux'
			puts "运行平台：#{RUBY_PLATFORM} 通过"
		else
			puts "运行平台：#{RUBY_PLATFORM} 不通过"
			exit
		end

		版本数组=RUBY_VERSION.split('.')
		版本数组.pop
		版本=版本数组.join('.')
		if a在b其中? 版本,'2.3 2.4 2.5'
			puts "版本号：#{RUBY_VERSION} 通过"
		else
			puts "版本号：#{RUBY_VERSION} 不通过"
			exit
		end		
		
		gem列表=`gem list`
		gem列表.each_line {|x| 
			数组=x.chomp.delete(',').delete('(').delete(')').split(" ")
			gem名称=数组[0]
			gem最高版本号码=数组[1]

			if 	  gem名称 == 'activerecord'
				if M_基础方法.版本模式匹配(gem最高版本号码,/5\.2\.\d/)
					puts "#{gem名称} 检测通过"
				else
					puts "#{gem名称} #{gem最高版本号码}检测不通过，请使用gem安装5.2.x版本"
				end
			elsif gem名称 == 'net-ssh'
				if M_基础方法.版本模式匹配(gem最高版本号码,/4\.2\.\d/)
					puts "#{gem名称} 检测通过"
				else
					puts "#{gem名称} #{gem最高版本号码}检测不通过，请使用gem安装4.2.x版本"
				end
			elsif gem名称 == 'progress_bar'
				if M_基础方法.版本模式匹配(gem最高版本号码,/1\.2\.\d/)
					puts "#{gem名称} 检测通过"
				else
					puts "#{gem名称} #{gem最高版本号码}检测不通过，请使用gem安装1.2.x版本"
				end
			elsif gem名称 == 'curses'
				if M_基础方法.版本模式匹配(gem最高版本号码,/1\.2\.\d/)
					puts "#{gem名称} 检测通过"
				else
					puts "#{gem名称} #{gem最高版本号码}检测不通过，请使用gem安装1.2.x版本"
				end
			elsif gem名称 == 'wxl_console'
				if M_基础方法.版本模式匹配(gem最高版本号码,/0\.1\.\d/)
					puts "#{gem名称} 检测通过"
				else
					puts "#{gem名称} #{gem最高版本号码}检测不通过，请使用gem安装0.1.x版本"
				end
			elsif gem名称 == 'net-sftp'
                                if M_基础方法.版本模式匹配(gem最高版本号码,/2\.1\.\d/)
                                        puts "#{gem名称} 检测通过"
                                else
                                        puts "#{gem名称} #{gem最高版本号码}检测不通过，请使用gem安装2.1.x版本"
                                end
			else
				nil
			end
		}
		
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
		#p 线程并发_总数
		#p 线程并发_最末轮次_计数
		进度条 = ProgressBar.new(主机信息.count);


		#
		# 这部分异常处理，主要是为了兼容脚本里面调用doauto，因为无法正常输出进度条而导致的报错
		#
		begin
			进度条2=C_进度条.new 主机信息.count
		rescue Exception => e
			nil
		end
		

		#p 主机信息.count

		C_主机表.where(%Q[grp like '#{@主机grep}%']).each {|主机行|


				
			主机ip,用户名,密码,端口=主机行.ip,主机行.username,主机行.password,主机行.port
			线程数组 <<	Thread.new {
							if $脚本参数hash表["--behavior"]=='chpasswd'
								新密码=生成随机密码
								$命令类型='cmd'
								$命令信息="echo #{新密码}|passwd --stdin #{主机行.username}"
								
								远端执行命令(主机ip,用户名,密码,端口,@输出对象.生成一个队列) if $脚本参数hash表["--behavior"] == "chpasswd"
								主机行.password=新密码
								主机行.save
							elsif $脚本参数hash表["--behavior"] == "x"
								远端执行命令(主机ip,用户名,密码,端口,@输出对象.生成一个队列) 
							elsif $脚本参数hash表["--behavior"] == "push"
								推送文件到远端(主机ip,用户名,密码,端口,@本地路径,@远程路径,@输出对象.生成一个队列)
							elsif $脚本参数hash表["--behavior"] == "pull"
								拉取文件到本地(主机ip,用户名,密码,端口,@本地路径,@远程路径,@输出对象.生成一个队列)
							else
								nil
							end

							
							}
			线程数组_计数 += 1;

			if    线程并发_轮次计数 <= 线程并发_轮次最大 && 线程数组_计数 == 线程并发_总数
					begin
						进度条2.更新
					rescue Exception => e
						nil
					end
					
					#进度条.increment!
					线程数组.each {|x|	x.join } && 线程数组_计数=0;
					线程并发_轮次计数 += 1;
			elsif 线程并发_轮次计数 == 线程并发_轮次最大 && 线程数组_计数 == 线程并发_最末轮次_计数
					#进度条.increment!
					begin
						进度条2.更新
					rescue Exception => e
						nil
					end
					线程数组.each {|x|	x.join } && 线程数组_计数=0;
					线程并发_轮次计数 += 1;
			else
					#进度条.increment!
					begin
						进度条2.更新
					rescue Exception => e
						nil
					end
			end
			
			#进度条.increment!
		}
		@输出对象.读取_所有_队列(@配置文件["config"]["sshlog"])
		@输出对象.清空队列
	end
end

(C_自动化操作.new.检查环境 if $脚本参数hash表["--behavior"]=='checkenv') && exit;
(C_自动化操作.new.查询主机信息 if $脚本参数hash表["--behavior"]=='info') && exit;
(C_自动化操作.new.测试主机链接($脚本参数hash表["--host"]) if $脚本参数hash表["--behavior"]=='test')  && exit;

(C_自动化操作.new.修改密码 if $脚本参数hash表["--behavior"] == "chpasswd")  && exit;



C_自动化操作.new.并发执行 if a在b其中? $脚本参数hash表["--behavior"],'x push pull'


if $脚本参数hash表["--behavior"]=='console'
	$实例=C_自动化操作.new
	def show(主机匹配=nil)
		$实例.查询主机信息 主机匹配
	end
	def test(主机匹配=nil)
		$实例.测试主机链接 主机匹配
	end

	def x(命令=nil,主机匹配=nil)

		$命令信息,$命令类型=命令,"cmd"
		$实例.主机grep = 主机匹配
		$脚本参数hash表["--behavior"] = "x"
		$实例.并发执行
	end

	def help
		puts "可用的命令："
		puts "show test x "
	end

require "readline"
require "gdbm"  #支持中文
require 'socket'



class C_控制台
	
	def initialize(外部绑定=TOPLEVEL_BINDING)
		@命令段落=""
		@命令行提示符="->"
	end

	def 开启
		while 读取行 = Readline.readline(@命令行提示符, true)
			exit if 读取行=='exit' || 读取行=='quit' || 读取行=='exit;' || 读取行=='quit;';
			if ! 读取行.end_with? ";"
				@命令段落 << 读取行 + "\n"
				@命令行提示符=""
			else
				@命令段落 << 读取行
				@命令段落.delete_suffix!(';')
				
				#puts __FILE__
				#p $脚本参数hash表
				shell=%Q{#{__FILE__} -B=x --host=#{$脚本参数hash表['--host']} --cmd="#{@命令段落}"}
				#p shell
				system "#{shell}"
				@命令段落=''
				@命令行提示符="->"
			end
		end		
	end
end

	C_控制台.new.开启
end 

#来捕捉Ctrl-C
rescue Interrupt
	puts "强制中断"
end


