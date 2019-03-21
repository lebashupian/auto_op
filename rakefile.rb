require_relative "color"

namespace :mysql部署相关 do  #这里使用了命名空间，方便更好的区别任务类别
	#
	# 这里定义函数
	#
	def 安装pcre(主机=nil)
		exit if 主机 == nil
		#
		# 这行正常打印函数名称，你不需要修改这里
		#
		puts 多色显示(__method__.to_s.center(20,"#"),"黄色","蓝色","")
		#
		# 这里是真正你需要关注的地方，你需要在这里指定执行的命令或脚本。并指定运行的主机
		#
		puts `doauto.rb --behavior=x --cmd='sleep 0.1 && echo OK' --host=#{主机} --dryrun=on`
	end

	def 安装nginx(主机=nil)
		exit if 主机 == nil
		puts 多色显示(__method__.to_s.center(20,"#"),"黄色","蓝色","")
		puts `doauto.rb --behavior=x --cmd='sleep 0.1 && echo OK' --host=#{主机} --dryrun=on`
	end

	def 安装mysql
	end


	desc "安装pcre"
	task :安装pcre do
		host=ENV["task_manage_host"] || exit
		exit if host.size == 0
		安装pcre host 
	end

	desc "安装nginx"
	task :安装nginx do
		host=ENV["task_manage_host"] || exit
		exit if host.size == 0
		安装nginx host
	end
	
	desc "一键安装nginx和软件依赖"
	task :一键安装nginx和软件依赖 => [:安装pcre,:安装nginx]do
		puts "完成"
	end

end

