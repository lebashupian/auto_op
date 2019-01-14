module M_基础方法

	def 退出信息(参数=nil)
		puts "#{参数}"
		exit 1
	end

	def 打印空格(数量)
		空格="" ; 数量.times { 空格 += " " } ; return 空格;
	end
	module_function :退出信息,:打印空格
end

module M_功能方法
	
	def 版本检测
		可用版本=["2.3.x","2.4.x","2.5.x"]
		当前版本=''
		当前版本=RUBY_VERSION.split('.')[0] + "." +RUBY_VERSION.split('.')[1] + "." + 'x'
		if !可用版本.include?(当前版本)
			退出信息("ruby版本检查不通过,当前版本是#{RUBY_VERSION},可用版本列表是：#{可用版本}") 
		end
	end
	
	module_function :版本检测
end

module M_常量
	################################################
	# 	               命令行参数校验
	################################################
	# 帮助内容
	CONS_帮助信息=%Q{请携带命令行参数:
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
end

## 加载所有的库
require 'active_record'
#相关库资料：
#http://net-ssh.github.io/net-ssh/
#http://net-ssh.github.io/net-scp/
require 'net/ssh'
require 'net/scp'
require 'progress_bar'
require_relative 'output2'
require 'yaml'
require "curses"
require "wxl_console"	