#!/usr/bin/env ruby
# coding: utf-8
require "wxl_console"
$列表={}

def load
        i=0
        `rake --tasks`.each_line {|x|
                i += 1
                任务=x.split(' ')[1]
                $列表["#{i}"] = 任务
        }

end
load

def show
	i=0
	`rake --tasks`.each_line {|x|
		i += 1
		任务=x.split(' ')[1]
		$列表["#{i}"] = 任务
	}
	$列表.each {|k,v|
		puts "#{k}) #{v}"
	}
end

def start(i,host=nil)
	puts  $列表["#{i}"]
	任务=$列表["#{i}"]
	host_hash={'task_manage_host' => host}
	命令="rake #{任务}"
	system(host_hash,命令)
end
C_控制台.new.开启
