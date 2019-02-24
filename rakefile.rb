require_relative "color"

namespace :mysql部署相关 do  #这里使用了命名空间，方便更好的区别任务类别
	def 安装pcre
		puts 多色显示(__method__.to_s.center(20,"#"),"黄色","蓝色","")
		puts `doauto.rb --behavior=x --cmd='sleep 0.1 && echo OK' --host=.all.web --dryrun=on`
	end

	def 安装nginx
		puts 多色显示(__method__.to_s.center(20,"#"),"黄色","蓝色","")
		puts `doauto.rb --behavior=x --cmd='sleep 0.1 && echo OK' --host=.all.web --dryrun=on`
	end

	def 安装mysql
	end


	desc "安装pcre"
	task :安装pcre do
		安装pcre
	end

	desc "安装nginx"
	task :安装nginx do
		安装nginx
	end
	
	desc "一键安装nginx和软件依赖"
	task :一键安装nginx和软件依赖 => [:安装pcre,:安装nginx]do
		puts "完成"
	end

end

