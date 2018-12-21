#!/opt/ruby_2.2.3/bin/ruby
# coding: utf-8
# 
require 'net/http'
require "readline"
require 'json'
require 'mysql'
require 'progress_bar'

################
# 数据库连接
################

my_host="127.0.0.1"
my_user="root"
my_db="ssh"
my_pwd=""
=begin
create table log_info (
hostip varchar(20) not null,
type varchar(20) not null,
id int(10) auto_increment,
log_path varchar(1024),
PRIMARY KEY (`id`)
);
=end

############################################
# help 内容
############################################
(
	puts '帮助范例：';
	puts '----------------------------------------------------------------------------------'
	puts '添加log信息'
	puts '	log_fx.rb addlog "xxx.xxx.xxx.xxx" "webserver" "../tmp/log/xxx.log"';
	puts '----------------------------------------------------------------------------------' 
	puts '展示目前的log，只显示日志文件确实存在的记录，类型为空代表查询所有的'
	puts '	log_fx.rb showlog [类型]'
	puts '----------------------------------------------------------------------------------' 
	puts '展示以往记录的正则表达式命令'
	puts '	log_fx.rb showre'
	puts '----------------------------------------------------------------------------------' 
	puts '分析日志'
	puts %q{ 
		命令      分析  日志编号  正则命令  动作编号（1：完全输出，2：聚合输出） 
		  |        |      |          |        |'
		log_fx.rb  fx     16      '\d{3}'     2
		log_fx.rb  fxaddr 16      '\d{3}'     2
		}
) if ARGV[0] == 'help' or ARGV[0] == nil




$数据库连接 = Mysql::new(my_host, my_user, my_pwd, my_db)

############################################
# 函数
############################################


def 获取文件行数(文件)  #用于给进度条初始化
	i=0;f=File.open(文件,'r');f.each_line { i += 1 };f.close;return i;
end

def 添加log信息(ip,type,path) #用于添加log记录到数据库中
	sql=%Q{insert into log_info (hostip,type,log_path) values("#{ip}","#{type}","#{path}")}
	$数据库连接.query(sql);
	$数据库连接.query("commit;")
	$数据库连接.query("select * from log_info order by id desc limit 1;").each {|x| p x}

end
#添加log信息('192.168.0.11',1,'/root/222.txt') if ARGV[0]="addlog"
添加log信息(ip=ARGV[1],type=ARGV[2],path=ARGV[3]) if ARGV[0]=="addlog"

def 查看log信息(type)
	puts "    IP         主机类  日志号     日志路径"
	$数据库连接.query("select * from log_info where type like \'%#{type}%\' order by id desc;").each {|x| 
		 p x if File.exist?(x[3])
	}
end

查看log信息(type=ARGV[1]) if ARGV[0]=="showlog"

def 分析日志(日志号码,正则='\d',动作='1',延迟时间=nil)
	日志路径=nil
	正则结果=nil
	开始时间=Time.new
	延迟时间=延迟时间.to_f if 延迟时间 != nil

	puts  "######################################################"
	puts  "###     如果你希望命令被记录，请添加注释      ########"
	puts  "###     否则，请回车                          ########"
	puts  "######################################################"

	读取行 = Readline.readline("正则命令注释：", true)
	`echo '#{正则} <--- #{读取行}' >> #{__dir__}/cmd_gre.log` if 读取行 != ''; #将正则命令记录到本地文件中



	统计哈希=Hash.new
	$数据库连接.query("select log_path from log_info where id = \'#{日志号码}\';").each {|x| 日志路径=x[0].to_s}
	#p 日志路径
	进度条 = ProgressBar.new(获取文件行数(日志路径));
	f=File.open(日志路径,'r')
	f.each_line {|行|
		正则结果=Regexp.new(正则).match(行)
		#####################
		# 动作1：完全输出
		# 动作2：汇聚输出
		#####################
		puts 正则结果 if (正则结果 && 动作=='1') 
		if (正则结果 && 动作=='2') 
			统计哈希["#{正则结果}"] ||= 0;  #没有，先初始化为0
			统计哈希["#{正则结果}"] +=  1;  #累加1
		end
		#如果是设置额延迟小于0.001将不再会有明显的延迟减小效果。如果你不希望延迟，最好的做法是将参数置为空
		sleep 延迟时间 if 延迟时间 != nil
		进度条.increment!
	}
	f.close
	if  动作=='2'
		统计哈希.sort {|x,y| x[1]<=>y[1]}.each {|x|
			统计K,数量V = x[0],x[1]
#=begin
			#create table iptabs(ip地址 varchar(20),国家 varchar(20),地区 varchar(20),城市 varchar(20));
			#数据库连接.execute("insert into iptabs(ip地址,ip所属国家) values('#{ip地址}','#{ip所属国家}');")
			if ARGV[0]=="fxaddr"
				uri = URI("http://ip.taobao.com/service/getIpInfo.php?ip=#{统计K}")
				哈希=JSON.parse(Net::HTTP.get(uri))
				ip地址=    哈希["data"]["ip"]
				ip所属国家=哈希["data"]["country"]
				ip所属区域=哈希["data"]["area"]
				ip所属省份=哈希["data"]["region"]
				ip所属城市=哈希["data"]["city"]
				ipinfo = sprintf("%-15s",ip地址)     + ":" + 
						 sprintf("%-8s",ip所属国家) + ":" +
						 sprintf("%-8s",ip所属区域) + ":" +
						 sprintf("%-8s",ip所属省份) + ":" +
						 sprintf("%-8s",ip所属城市)			
				puts "#{ipinfo}:#{数量V}"
				sleep 0.5
			elsif ARGV[0]=="fx"
				puts sprintf("%-80s",统计K) + "=>" + sprintf("%10s",数量V)
				puts "----------------------------------------------------------------------------------------------"
			else
				echo "未知的参数"
				exit 102
			end

#=end
		}
	end
	结束时间=Time.new
	print "分析花费时长：";
	print sprintf("%10.3f",结束时间-开始时间);
	print "秒\n";
end

分析日志(ARGV[1],ARGV[2],ARGV[3],ARGV[4]) if (ARGV[0]=="fx" || ARGV[0]=="fxaddr")
(puts `cat #{__dir__}/cmd_gre.log`) if ARGV[0] == 'showre'

exit
while 读取行 = Readline.readline(">", true)
	exit                          if 读取行=='exit' || 读取行=='quit';
end;