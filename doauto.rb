#!/usr/bin/env ruby
# coding: utf-8

def exit_msg(参数=nil)
	puts "#{参数}"
	exit 1
end

#####################################################################
#                检查ruby的版本是否和程序兼容
#                因为当前版本所使用的mysql连接库是mysql,这个库比较旧,新的库叫mysql2
#                且,2.4版本之后,无法顺利安装.所以该版本,仅支持到2.3
#              
可用版本=["2.2.x","2.3.x"]
当前版本=''
当前版本=RUBY_VERSION.split('.')[0] + "." +RUBY_VERSION.split('.')[1] + "." + 'x'
exit_msg("ruby版本检查不通过,当前版本是#{RUBY_VERSION},可用版本列表是：#{可用版本}") if !可用版本.include?(当前版本)
puts "当前ruby版本是#{RUBY_VERSION}"
#





begin  #所有程序都放在一个测试块中，来捕捉Ctrl-C
#相关库资料：
#http://net-ssh.github.io/net-ssh/
#http://net-ssh.github.io/net-scp/
require 'mysql'
require 'net/ssh'
require 'net/scp'
require 'progress_bar'
require_relative 'output2'
require 'yaml'
require "curses"

################################################
# 	               命令行参数校验
################################################
# 帮助内容
帮助信息=%Q{请携带命令行参数:
	--help       显示帮助信息
	--behavior=cs 测试主机链接
	--behavior=scp        远程传输文件
	--behavior=x   远程执行命令
	--behavior=info       打印所有的主机信息
	--behavior=dbinit       初始化数据库结构
	--behavior=greplog       初始化数据库结构
注意：如果程序的输出太长，超过终端缓存行数，可以通过/tmp/下的'ssh.log.日期' 来查看日志
	范例
	doauto.rb --behavior=cs  
	doauto.rb --behavior=dbinit
	doauto.rb --behavior=scp --host=xxx --local=xxx --remote=xxx --direction=push|pull
	doauto.rb --behavior=x --cmd=xxx --host=xxx
	doauto.rb --behavior=x --script=xxx --host=xxx
	doauto.rb --behavior=greplog --host=xxx --logfile=xxx --grepword=xxx --regex=xxx
}





#######################################################
# 脚本参数处理
#######################################################
# 首先设置默认值
$脚本参数hash表={}
#$脚本参数hash表["--cmd"]="hostlist"
# 使用脚本的参数赋值重新覆盖默认参数
ARGV.each {|x|
  $脚本参数hash表.merge!({"#{x.split("=")[0]}" => "#{x.split("=")[1]}"});
}

def 退出信息(参数=nil)
	puts "#{参数}"
	exit 1
end


################
# 命令提示符判断
# 先判断是否有参数
退出信息("没有指定参数,你可以先使用--help查看一下帮助内容") if ARGV[0] == nil
	
# 判断是否是需要help
(帮助信息.each_line {|x| puts x};exit 2;) if ARGV.include?("--help")

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

退出信息("你需要指定--behavior参数") if 没有? "--behavior"

if 有? "--behavior" and !(a在b其中? $脚本参数hash表["--behavior"],'x scp cs info greplog dbinit')
	退出信息("--behavior参数的可选值有 x scp cs info greplog dbinit") 
end

if 等于? "--behavior","x" and ( ( 没有? "--script" and 没有? "--cmd" ) or ( 有? "--script" and 没有值? "--script" ) or ( 有? "--cmd" and 没有值? "--cmd" ) ) 
	退出信息("必须指定--script=xxx或--cmd=xxx") 
end

if 等于? "--behavior","x" and ( 没有? "--host" or ( 有? "--host" and 没有值? "--host" ) )
	退出信息("必须指定--host=xxx")
end

if 等于? "--behavior","scp" and ( k或v缺失? "--local" or k或v缺失? "--remote" or k或v缺失? "--direction" or k或v缺失? "--host")
	退出信息("必须指定--host=xxx --local=xxx --remote=xxx --direction=push|pull")
end

if 等于? "--behavior","greplog" and ( k或v缺失? "--host" or k或v缺失? "--logfile" or 没有? "--grepword" or k或v缺失? "--regex")
	退出信息("必须指定--host=xxx --logfile=xxx --grepword=xxx --regex=xxx")
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
#####################################################################################################
#                                             配置部分
#####################################################################################################
#                
#####################################################################################################
#####################################################################################################
YAML_FILE="#{__dir__}/config/doauto.yml"
配置文件=YAML.load(File.open(YAML_FILE,'r'));
#p 配置文件["config"]["sshlog"]
################
# 数据库连接
################
my_host=配置文件["database"]["db_host"]
my_user=配置文件["database"]["db_user"]
my_db=  配置文件["database"]["db_schema"]
my_pwd= 配置文件["database"]["db_pwd"]
数据库连接 = Mysql::new(my_host, my_user, my_pwd, my_db)
$数据库连接2 = Mysql::new(my_host, my_user, my_pwd, my_db)

$数据库连接2.query('delete from run_log;');
$数据库连接2.query('commit;');
################
# 标准输出对象
################
输出对象=Output.new
################
# 数据库表结构
################
#+----------+-------------+------+-----+---------+----------------+
#| Field    | Type        | Null | Key | Default | Extra          |
#+----------+-------------+------+-----+---------+----------------+
#| id       | int(10)     | NO   | PRI | NULL    | auto_increment | 自增ID，只是为了保证数据条目的唯一性。
#| ip       | varchar(20) | NO   |     | NULL    |                | 
#| username | varchar(50) | YES  |     | NULL    |                | 
#| password | varchar(50) | YES  |     | NULL    |                |
#| port     | int(6)      | NO   |     | 22      |                |
#| grp      | varchar(30) | NO   |     | .all.   |                | 这个grp是一个字符串，程序操作的时候，会使用sql的like语句%%来匹配主机
#| used     | varchar(6)  | NO   |     | Y       |                |
#+----------+-------------+------+-----+---------+----------------+
####################################################################################################


#########################
# 首次初始化数据库
#########################
def 初始化数据库结构(数据库连接参数,初始化SQL)
	初始化SQL.each_line(sep=';') {|sql | 数据库连接参数.query(sql); }
	puts "初始化完成"
	exit
end
初始化数据库结构(数据库连接,File.open("#{__dir__}/config/init.sql","r")) if $脚本参数hash表["--behavior"]=='dbinit'


sql_text=%q{
	select 
		ip,username,password,port,grp
	from 
		hostinfo
	where 
		used = 'Y'
			and
		grp like '%} + "#{$脚本参数hash表["--host"]}" + %q{%'
			order by ip asc
		}
puts sql_text if 参数有? "--debug"

主机信息=数据库连接.query(sql_text);
退出信息("没有匹配到任何主机") if 主机信息.num_rows == 0


主机信息=数据库连接.query(sql_text);

################
# 方法
################
def 打印空格(数量)
	空格="" ; 数量.times { 空格 += " " } ; return 空格;
end

def 查询主机信息(数据库连接参数)
	主机信息=数据库连接参数.query("select ip,username,password,port,grp,used from hostinfo order by grp");
	
	ip_行长,username_行长,grp_行长,used_行长=0,0,0,0
	数据库连接参数.query("select ip from hostinfo"       ).each {|行| ip_行长=      行[0].size if ip_行长       < 行[0].size};主机信息.data_seek(0) #重置查询行的游标
	数据库连接参数.query("select username from hostinfo" ).each {|行| username_行长=行[0].size if username_行长 < 行[0].size};主机信息.data_seek(0) #重置查询行的游标
	数据库连接参数.query("select grp from hostinfo"      ).each {|行| grp_行长=     行[0].size if grp_行长      < 行[0].size};主机信息.data_seek(0) #重置查询行的游标
	数据库连接参数.query("select used from hostinfo"     ).each {|行| used_行长=    行[0].size if used_行长     < 行[0].size};主机信息.data_seek(0) #重置查询行的游标
	
	puts "用户@  IP地址        主机类型(操作匹配字符串)   可用状态"
	主机信息.each {|主机行|
		主机ip,用户名,密码,端口,类型,可用=主机行[0],主机行[1],主机行[2],主机行[3],主机行[4],主机行[5]
		
		puts "#{用户名}#{打印空格(username_行长-用户名.size)}" + 
			 "@#{主机ip}#{打印空格(ip_行长-主机ip.size)}" + 
			 "|#{类型}#{打印空格(grp_行长-类型.size)}"  +
			 " |     #{可用}"
	}
end

(查询主机信息(数据库连接) if $脚本参数hash表["--behavior"]=='info') && exit;


def 测试主机链接(主机信息参数,输出队列参数)
	进度条 = ProgressBar.new(主机信息参数.num_rows);
	主机信息参数.each {|主机行|
		主机ip,用户名,密码,端口=主机行[0],主机行[1],主机行[2],主机行[3]
		begin 
			Net::SSH.start(主机ip,用户名,:port => 端口 , :password => 密码) do |ssh|
				  输出命令 = ssh.exec!("
				  	date > /dev/null 2>>/dev/shm/ssh.rb.error.log && echo #{主机ip}'连接成功' || echo #{主机ip}'连接成功,但命令执行失败';
				  ")
				  输出命令.each_line {|行|
				  	输出队列参数 << 行
				  }
			end
			进度条.increment!
		rescue  => 错误信息
			puts "#{主机ip}"+"连接不成功 "+"#{错误信息}"
		ensure
			#exit 101
		end		
	}
	主机信息参数.data_seek(0) #重置查询行的游标
end

(测试主机链接(主机信息,输出对象.生成一个队列) if $脚本参数hash表["--behavior"]=='cs') && 输出对象.读取_所有_队列(配置文件["config"]["sshlog"]) && exit;

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

def 远端执行命令(主机ip参数,用户名参数,密码参数,端口参数,输出队列参数)
	begin
		Net::SSH.start(主机ip参数,用户名参数,:port => 端口参数 , :password => 密码参数) do |ssh|
				a=$数据库连接2.query("insert into run_log (ip,port,status,start_time) values('#{主机ip参数}','#{端口参数}','start','#{Time.new.to_s.byteslice(0,19)}');");
				a=$数据库连接2.query("commit;");
				if $命令类型 == 'cmd'
			  		输出命令 = ssh.exec!($命令信息)
				elsif $命令类型 == 'script'

					退出信息("#{$命令信息}脚本文件不存在") if !File.file?($命令信息)
					脚本文件=File.open($命令信息,"r");
					脚本文件行数 = 0;脚本文件.each_line {|x|  脚本文件行数 += 1 };脚本文件.rewind
					脚本文件.each_line {|行|
						输出命令 ||= ''
						输出命令 << ssh.exec!("#{行}")
					}
					
				else
					退出信息("无效的命令类型,请检查你的参数")
				end

			  	输出命令.each_line {|行|
			  		输出队列参数 << "@主机" + "#{主机ip参数}".split('.').values_at(2,3).join('.') + " -> " + 行
			  	}
			  	sleep 1
				a=$数据库连接2.query("update run_log set status='end',end_time='#{Time.new.to_s.byteslice(0,19)}' where ip='#{主机ip参数}' and  port='#{端口参数}';");
				a=$数据库连接2.query("commit;");		
		end
	rescue  => 错误信息 #因为是并发的连接，可能会获取多行错误信息
		puts "#{错误信息}"
	ensure
		#exit 102
	end
end


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

################
# 并发执行
################

线程数组=[];
线程数组_计数=0;

线程并发_总数=配置文件["config"]["thread_concurrency"].to_i
线程并发_轮次计数=1;
线程并发_轮次最大=(主机信息.num_rows.to_f/线程并发_总数.to_f).ceil;
线程并发_最末轮次_计数=主机信息.num_rows % 线程并发_总数
进度条 = ProgressBar.new(主机信息.num_rows);

主机信息.each {|主机行|
	主机ip,用户名,密码,端口=主机行[0],主机行[1],主机行[2],主机行[3]
	线程数组 <<	Thread.new {
	 				远端传输文件(主机ip,用户名,密码,端口,输出对象.生成一个队列,$传输文件["本地文件"],$传输文件["远程文件"],$传输文件["动作"]) if $脚本参数hash表["--behavior"] == 'scp'
					远端执行命令(主机ip,用户名,密码,端口,输出对象.生成一个队列) if $脚本参数hash表["--behavior"] == "x"
					正则分析日志(主机ip,用户名,密码,端口,输出对象.生成一个队列,$正则参数["日志文件名"],$正则参数["grep字符串"],$正则参数["正则表达式"]) if $脚本参数hash表["--behavior"] == 'greplog'
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
主机信息.data_seek(0) #重置查询行的游标

输出对象.读取_所有_队列(配置文件["config"]["sshlog"])

#来捕捉Ctrl-C
rescue Interrupt
	puts "强制中断"
end
