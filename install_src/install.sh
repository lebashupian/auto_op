#!/bin/bash
	echo "安装系统依赖的rpm包"
	yum -y groupinstall "Development tools"
	yum -y install readline-devel
	yum -y install lrzsz
	yum -y install openssl-devel
	yum -y install gdbm-devel
	yum -y install mysql-server
	yum -y install mysql
	yum -y install mysql-devel
	yum -y install wget
	service mysqld start
	echo 编译安装ruby
	wget https://cache.ruby-lang.org/pub/ruby/2.5/ruby-2.5.3.tar.gz
	tar -zxvf ruby-2.5.3.tar.gz
	cd ruby-2.5.3
	mkdir /opt/ruby2.5.3
	./configure --prefix=/opt/ruby2.5.3/
	make && make install

	echo "将ruby的bin路径加入系统环境变量"
cat <<EOF>> /etc/profile
export PATH=/opt/ruby2.5.3/bin:$PATH
EOF
source /etc/profile

	echo "修改gem源的为ruby-china"
	gem sources --remove https://rubygems.org/
	gem sources --add https://gems.ruby-china.com

	echo "安装gem的bundle"
	gem install bundle

	echo "使用bundle安装gem依赖库"
	bundle install

	echo "完成,请重新登录shell，加载环境变量"
