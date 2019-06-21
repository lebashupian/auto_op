#!/bin/bash
i=1
while [[ $i -le 200 ]];
do
echo $i
ifconfig eth0:139:$i 192.168.139.$i
sleep 0.05
i=$(($i+1))
done
