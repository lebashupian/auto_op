<<<<<<< HEAD
# auto_op
<<<<<<< HEAD
=======
#auto_op
>>>>>>> v2.0.0
批量远端主机执行命令的工具.
这个是对net/ssh库的再次封装。底层依赖是net/ssh库。

它重点解决了三个问题
第一，它解决并发执行的问题，
第二，它封装了ruby的ssh库，提供了更好用的方法
第三，它提供了很好的进度显示，和执行界面的回显。
第四，它提供了人性化的功能，比如一键批量修改主机密码。

它提供的命令入口，没有屏蔽shell的语法。因为我个人觉得，对于工程师而言，封装shell是画蛇添足的做法，那会提高学习成本，浪费时间。就像你给中国人封装汉语一样，没有必要。你以前怎么写shell脚本或命令，你在auto_op中还怎么写，不会有任何变化。

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
			....略


从零开始
1，你首先要有一个centos的环境，比如centos 6.10
	你需要安装如下rpm包
	yum -y groupinstall "Development tools"
	yum -y install readline-devel
	yum -y install lrzsz
	yum -y install openssl-devel
	yum -y install gdbm-devel
	yum -y install mysql-server
	yum -y install mysql
	yum -y install mysql-devel


2，安装ruby
	建议版本。2.5.x，这里演示的版本是2.5.3
	tar -zxvf ruby-2.5.3.tar.gz
	cd ruby-2.5.3
	mkdir /opt/ruby2.5.3
	./configure --prefix=/opt/ruby2.5.3/
	make && make install

cat <<EOF>> /etc/profile
export PATH=/opt/ruby2.5.3/bin:$PATH
EOF
source /etc/profile

gem sources --remove https://rubygems.org/
gem sources --add https://gems.ruby-china.com
=======
自动化运维工具，用于批量发布命令到远端主机。
>>>>>>> 05db34b9fce26d6cb47b11e0006d207d1c189298

