#!/opt/ruby-2.5.1/bin/ruby -w
# coding: utf-8

class C_进度条
	@@进度条数量=0
	def initialize(循环次数,进度条名称='',进度条长度=10)
		@当前循环次数=1
		@循环次数=循环次数
		@进度条名称=进度条名称
		@进度条长度=进度条长度
		统计
	end

	def 更新
		当前比例=((@当前循环次数.to_f/@循环次数)*@进度条长度).to_i
		剩余比例=@进度条长度-当前比例
		输出=''
		输出 << @进度条名称
		输出 << "|";
		当前比例.times { 输出 << "#"};
		剩余比例.times { 输出 << " "};
		输出 << "|";
		@当前循环次数 += 1
		return 输出
	end

	def C_进度条.返回统计
		return @@进度条数量
	end

	def 统计
		@@进度条数量 += 1
	end

	private :统计
end

=begin
def 进度条(当前循环次数,循环次数)
	循环次数=循环次数
	当前次数=((当前循环次数.to_f/循环次数)*100).to_i
	剩余次数=100-当前次数
	print "|";
	当前次数.times { print "#"};
	剩余次数.times {print " "};
	print "|";
	if 剩余次数 == 0
	print "\n"
	else
	print "\r" 	#光标到行首
	$stdout.flush
	end
end
10.times {|x|
进度条(x+1,10)
sleep 0.05
}
=end
