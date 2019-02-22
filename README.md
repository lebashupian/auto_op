# auto_op
批量执行命令的工具.
这个是对net/ssh库的再次封装。底层依赖是net/ssh库。

它可以做到，批量通过ssh通道向大量的服务器发送shell命令。

它使用mysql来记录主机信息和运行信息。


doauto --help
请携带命令行参数:
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

	注意：如果程序的输出太长，超过终端缓存行数，可以通过/tmp/下的'ssh.log.日期' 来查看日志
		用例
		doauto.rb --behavior=test 
		doauto.rb --behavior=dbinit
		doauto.rb --behavior=x --cmd=xxx --host=xxx
		doauto.rb --behavior=x --script=xxx --host=xxx
		doauto.rb --behavior=chpasswd --host=xxx
		doauto.rb --behavior=console
		doauto.rb -B=checkenv
