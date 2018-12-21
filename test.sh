#!/bin/bash
source /etc/profile
source ~/.bash_profile
port=10022
while [[ $port -lt 10099 ]]
do
mysql -e "use auto_op;insert into hostinfo (ip,username,password,port,grp,used) values('192.168.137.102','root','1234',"$port",'ceshi','Y');commit;"
port=$(($port+1))
done
