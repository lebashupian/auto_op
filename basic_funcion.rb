module M_基础方法

	def 退出信息(参数=nil)
		puts "#{参数}"
		exit 1
	end

	def 打印空格(数量)
		空格="" ; 数量.times { 空格 += " " } ; return 空格;
	end

	def 版本模式匹配(版本号,模式)
		版本号.match? 模式
	end

	module_function :退出信息,:打印空格,:版本模式匹配
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
		--faq        显示常见问题的解决方式
		--behavior 和 -B 等价
		--behavior=test 测试主机链接
		--behavior=x   远程执行命令
		--behavior=info       打印所有的主机信息
		--behavior=dbinit       初始化数据库结构
		--behavior=chpasswd     自动修改主机账户密码，密码随机生成20位
		--behavior=console      使用交互模式
			x 'ls','.all'   交互模式下使用执行命令
		--behavior=checkenv 检查运行环境（命令会检查ruby版本、和gem第三方库的版本是否符合要求）
		--behavior=push 推送文件到远端（支持目录推送）
		--behavior=pull 拉取文件到本地（不支持目录拉取）
		--dryrun=on 不真实执行命令。
	注意：如果程序的输出太长，超过终端缓存行数，可以通过/tmp/下的'ssh.log.日期' 来查看日志
		用例
		doauto.rb --behavior=test 
		doauto.rb --behavior=dbinit
		doauto.rb --behavior=x --cmd=xxx --host=xxx
		doauto.rb --behavior=x --script=xxx --host=xxx
		doauto.rb --behavior=chpasswd --host=xxx
		doauto.rb --behavior=console
		doauto.rb -B=checkenv
		doauto.rb -B=push --local=/root/nginx.tar.gz --remote=/root/nginx.tar.gz --host=.all.web.
                doauto.rb -B=pull --local=/root/message --remote=/var/log/message --host=.all.web #从多个主机拉取数据到本地，本地的文件名会自动附加主机ip信息
	}
	#FAQ
	CONS_FAQ=%Q{
		FAQ:
		1,如果，你通过命令远程ssh，发现没有交互登录后所具有的环境变量，报命令找不到的错误。请将/etc/profile 和 ~/.bash_profile 里面配置的环境变量，复制到
		~/.bashrc中
		2,--host是如何做映射的到具体的ip的。这里的设计有点类似于域名。如果，你查询主机数据，你会看到以下的数据条目。
                  | id   | ip              | username | password | port  | grp             | used |
                  +------+-----------------+----------+----------+-------+-----------------+------+
                  | 2877 | 192.168.137.41  | root     | xxxxxxx  |    22 | .all.web.py     | Y    |
                  | 2878 | 192.168.137.42  | root     | xxxxxxx  |    22 | .all.web.py     | Y    |
                  | 2879 | 192.168.137.43  | root     | xxxxxxx  |    22 | .all.web.php.43 | Y    |
                  | 2880 | 192.168.137.44  | root     | xxxxxxx  |    22 | .all.web.php.44 | Y    |
                  | 2881 | 192.168.137.45  | root     | xxxxxxx  |    22 | .all.web.php.45 | Y    |
		假如，你的--host=.all. 代表你要在所有的主机上执行命令.
		假如，你的--host=.all.web.php. 代码你是在 43、44、45这三台机器上执行命令
		所以，它是一个从前往后模糊匹配的方式实现的。
		3, 假如你的命令返回 Too many connections，你需要检查你的mysql配置文件 my.cnf max_connections 是不是太小了

	}
end

## 加载所有的库
require 'active_record'
#相关库资料：
#http://net-ssh.github.io/net-ssh/
#http://net-ssh.github.io/net-scp/
require 'net/ssh'
#require 'net/scp'
require 'net/sftp'
require 'progress_bar'
require_relative 'output2'
require 'yaml'
require "curses"
#require "wxl_console"	
