# auto_op
批量远端主机执行命令的工具.
这个是对net/ssh库的再次封装。底层依赖是net/ssh库。

它可以做到，批量通过ssh通道向大量的服务器发送shell命令（也可以是一个脚本）

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


hostadd.rb 
		这是一个导入主机信息到mysql数据库的脚本。里面有一个现成的例子
		通常，你应该匹配部署一批主机，主机的IP，最好是确定好的和连续的。密码是统一的。
		你可以修改这个脚本。匹配一次性导入到数据库中。
		然后通过doauto --behavior=chpasswd --host=xxx 来匹配的重置密码为随机字符


task_manager 是一个部署任务的管理器，底层使用的是ruby的rake，同时它调用了doauto这个脚本程序。
			需要部署的任务，你需要定义在 task_manager.conf 中，如果你有python的编程经验，你应该可以很好的理解定义文件的例子
			以下是一个命令行的演示

			[root@ruby auto_op]# task_manager
			->show;
			1) mysql部署相关:一键安装nginx和软件依赖
			2) mysql部署相关:安装nginx
			3) mysql部署相关:安装pcre
			->1;
			->start 1;
			mysql部署相关:一键安装nginx和软件依赖
			#######安装pcre######