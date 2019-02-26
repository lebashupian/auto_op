#!/bin/bash

#
# 这是一个mysql编译安装的脚本。也是auto_op的演示脚本
#

cp /mnt/cmake-2.8.12.tar.gz /root

cp /mnt/mysql-5.6.42.tar.gz /root


yum  -y install gcc gcc-c++ ncurses-devel perl bison
cd /root/;
tar -zxvf cmake-2.8.12.tar.gz
cd cmake-2.8.12
./configure
gmake
make install

groupadd mysql
useradd mysql -g mysql

cat <<EOF>> /etc/security/limits.conf
mysql soft nproc 2047
mysql hard nproc 16384
mysql soft nofile 1024
mysql hard nofile 65535
EOF


mkdir -p /opt/mysql
mkdir -p /opt/mysql/data
mkdir -p /opt/mysql/data/log-bin
mkdir -p /opt/mysql/data/relay-log/
mkdir -p /opt/mysql/etc
chown mysql.mysql -R /opt/mysql

cd /root;tar -zxvf mysql-5.6.42.tar.gz
cd mysql-5.6.42
cmake -DCMAKE_INSTALL_PREFIX=/opt/mysql \
-DSYSCONFDIR=/opt/mysql/etc \
-DMYSQL_DATADIR=/opt/mysql/data \
-DMYSQL_UNIX_ADDR=/opt/mysql/mysqld.sock \
-DMYSQL_TCP_PORT=3306 \
-DDEFAULT_CHARSET=utf8 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_COLLATION=utf8_general_ci \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_ARCHIVE_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITH_PERFSCHEMA_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DENABLED_LOCAL_INFILE=1
make && make install

mkdir -p /opt/mysql/etc
cat <<EOF>> /opt/mysql/etc/my.cnf
[client]
port=3306
socket=/opt/mysql/etc/mysql.sock
[mysqld]
port=3306
user=mysql
socket=/opt/mysql/etc/mysql.sock
pid-file=/opt/mysql/etc/mysql.pid
basedir=/opt/mysql
datadir=/opt/mysql/data
open_files_limit=10240
explicit_defaults_for_timestamp=true
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
federated
skip-name-resolve
max_connections = 10000
###############################主从同步相关
server-id=1
log_slave_updates=1
slave_skip_errors = 1062
###############################buffer
max_allowed_packet=256M
max_heap_table_size=256M
net_buffer_length=8K
sort_buffer_size=2M
join_buffer_size=4M
read_buffer_size=2M
read_rnd_buffer_size=16M
###############################log
log-bin=/opt/mysql/data/log-bin/mysql-bin
binlog_cache_size=32M
max_binlog_cache_size=512M
max_binlog_size=512M
binlog_format=mixed
log_output=FILE
log_error=mysql-error.log
slow_query_log=1
slow_query_log_file=slow_query.log
general_log=0
general_log_file=general_query.log
expire_logs_days=30
relay_log=/opt/mysql/data/relay-log/mysql-relay-log
###############################InnoDB
innodb_data_file_path=ibdata1:1024M:autoextend
innodb_log_file_size=256M
innodb_log_files_in_group=3
innodb_buffer_pool_size=512M
#############################commit
transaction_isolation = READ-COMMITTED
autocommit=1
[mysql]
no-auto-rehash
default-character-set=utf8
EOF
chown mysql.mysql -R /opt/mysql

/opt/mysql/scripts/mysql_install_db --user=mysql --basedir=/opt/mysql --datadir=/opt/mysql/data
rm -f /etc/my.cnf;rm -f /opt/mysql/my.cnf
cp /opt/mysql/support-files/mysql.server /etc/init.d/mysqld
chmod 755 /etc/init.d/mysqld
chkconfig --add mysqld
chkconfig mysqld on

echo 'PATH=/opt/mysql/bin:$PATH' >> /root/.bash_profile
echo 'PATH=/opt/mysql/bin:$PATH' >> /etc/profile
echo 'export PATH' >> /root/.bash_profile
source /root/.bash_profile

