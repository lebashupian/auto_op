auto_op
批量远端主机执行命令的工具.
这个是对net/ssh库的再次封装。底层依赖是net/ssh库。

它重点解决了三个问题
第一，它解决并发执行的问题，
第二，它封装了ruby的ssh库，提供了更好用的方法
第三，它提供了很好的进度显示，和执行界面的回显。
第四，它提供了人性化的功能，比如一键批量修改主机密码。

它提供的命令入口，没有屏蔽shell的语法。所以，你几乎不花费学习成本，你就可以像平常一样，在远程主机上执行命令。你以前怎么写shell脚本或命令，你在auto_op中还怎么写，不会有任何变化。

它可以做到，批量通过ssh通道向大量的服务器发送shell命令（也可以是一个脚本）

它使用mysql来记录主机信息和运行信息。


doauto --help
请携带命令行参数:
		--help       显示帮助信息
		--faq        显示常见问题的解决方式、和一些问题的冗长说明
		--behavior 和 -B 等价
		--behavior=test 测试主机链接，有时候提前测试一下到远程主机的连接是否正常还是非常有必要的。
		--behavior=x   远程执行命令，他支持两种命令类型，一种是单纯的命令或组合命令（--cmd），一种是通过一个脚本文件给与命令集合（--script）。
		--behavior=info       打印主机信息，当时通过--host来指定主机集合的时候，提前通过命令看下主机信息比如IP，也许是一个好习惯
		--behavior=dbinit       初始化数据库结构，当地第一次使用这个工具的时候，你需要编辑config目录下的配置文件，然后指定连接的数据库，然后初始化它。
		--behavior=chpasswd     自动修改主机账户密码，随机生成20位由大小写字母和数字组成的密码
		--behavior=console      使用交互模式。目前它支持behavior=x的情景
			x 'ls','.all'   交互模式下使用执行命令
		--behavior=checkenv 检查运行环境（命令会检查ruby版本、和gem第三方库的版本是否符合要求）
		--dryrun=on 这个命令尤其适用于task_manager中，它表示，仅仅模拟执行流程，而不是真的在远程执行命令。一般在配置完成task_manager.conf之后，需要测试执行流程的时候使用
	注意：如果程序的输出太长，超过终端缓存行数，可以通过/tmp/下的'ssh.log.日期' 来查看日志
		用例
		doauto.rb --behavior=test --host=.all.web.py
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
		然后通过doauto --behavior=chpasswd --host=xxx 来重置匹配主机的密码为随机字符


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
			....略


从零开始
1，克隆仓库
git clone https://github.com/lebashupian/auto_op.git
2，sh auto_op/install_src/install.sh #该文件会自动帮你完成依赖包和依赖库的安装，并会自动编译ruby到/opt目录下，还会自动帮你安装一个mysql数据库
3，你需要参考hostadd.rb中的例子，添加主机信息到数据库。
4，然后你可以开始参考doauto的help信息来操作远程主机了
5，如果你需要定义很多的执行任务，并且定义执行任务之间的先后依赖关系，你需要参考task_manager.conf文件，修改里面的配置。然后通过task_manager命令来发动任务执行
