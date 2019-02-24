#!/opt/ruby_2.2.3/bin/ruby
# coding: utf-8
require_relative "color"
class Output
	def initialize
		@队列数组=Array.new
		@最末队列的游标 = 0
	end
	
	def 生成一个队列
		@队列数组 << Queue.new
		@最末队列的游标 += 1
		return @队列数组[@最末队列的游标-1]
	end

	def 清空队列
		@队列数组.clear
		@最末队列的游标 = 0
	end

	def 读取_所有_队列(local_log=false)
		当前时间=Time.new.to_s.byteslice(0,19)
		Dir.exist?("/var/log/auto_op") || Dir.mkdir("/var/log/auto_op")
		输出文件=File.new("/var/log/auto_op/ssh.log.#{当前时间}","w+") if local_log == true ;
		i=1
		@队列数组.each {|队列|
			puts 多色显示("输出通道:#{i},信息输出:".center(100,"-"),"黄色","","")
			队列.size.times {|读取次数|
				条目=队列.pop
				条目中主机部分=条目.split('->',2)[0] 
				条目中命令部分=条目.split('->',2)[1]  
				print 多色显示("行#{'%06d' % 读取次数}","黄色","","")
				print 多色显示("#{条目中主机部分}","青色","","")
				print 多色显示("#{条目中命令部分}","绿色","","")
				print "\n"
				#puts "行#{'%06d' % 读取次数} #{条目}"
				输出文件.syswrite("#{条目}\n") if local_log == true ;
			}
			i += 1;
		}
	end
end
=begin
输出对象=Output.new

队列1=输出对象.生成一个队列
队列2=输出对象.生成一个队列
100000.times {|x|
队列1 << "队列1:" + x.to_s
}

100000.times {|x|
队列2 << "队列2:" + x.to_s
}


输出对象.读取_所有_队列
=end
