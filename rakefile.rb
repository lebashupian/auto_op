

namespace :家庭相关 do  #这里使用了命名空间，方便更好的区别任务类别
	def 查看系统时间
		puts "第一个任务"
		puts `doauto.rb --behavior=x --cmd=date --host=.all.web`
	end

	def 查看主机名
		puts "第二个任务"
		puts `doauto.rb --behavior=x --cmd=hostname --host=.all.web`
	end


	desc "任务1"
	task :renwu1 do
	查看系统时间
	end

	desc "任务2"
	task :renwu2 do 
	查看主机名
	end
	
	desc "任务3"
	task :zuhe => [:renwu1,:renwu2]do
	end

end

