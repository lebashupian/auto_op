#!/opt/ruby-2.5.1/bin/ruby -w
# coding: utf-8

begin
	require 'socket'
	require "curses"
	require_relative 'process_bar'


	class C_运行标识
		def initialize
			@标识形状数组=['\\','|','/','-']
			@标识形状=@标识形状数组[0]
			@变化次数=0
		end

		def 更新形状
			@变化次数 += 1
			@标识形状 = @标识形状数组[@变化次数%4]
			return @标识形状
		end
	end

	class C_等待标识
		def initialize
			@标等待标识数组=['','.','..','...','....']
			@等待标识=@标等待标识数组[0]
			@变化次数=0			
		end
		def 更新标识
			@变化次数 += 1
			@等待标识 = @标等待标识数组[@变化次数%5]
			return @等待标识
		end		
	end

	标识=C_运行标识.new
	等待=C_等待标识.new


	a=nil
	b=nil
	c=nil
	d=nil

	`rm -f cmd_socket`
	
	Thread.new {
		UNIXServer.open("cmd_socket") {|服务|
			连接 = 服务.accept

			begin
				loop { 
					消息数组 = 连接.readline.chomp!.split("@@@")
					消息类型 = 消息数组[0]
					消息内容 = 消息数组[1]
					#p 消息类型,消息内容
					a=消息内容
				}
			rescue Exception => e
				if e.class.to_s == 'EOFError'
					sleep 0.5 
					retry					
				else
					p e.message
					exit 1
				end
			end
		}
	}

	Thread.new {
		  UNIXSocket.open("cmd_socket") {|客户端|
		  	10000000000.times {|x|
		  		客户端.puts "a@@@#{x}"
		  		sleep 0.001
		  	}
		  	客户端.close
		  }
	}

#sleep 1000

	Curses.init_screen
	Curses.curs_set(0)  # 0 表示隐藏光标

	#引入互斥的原因，是因为在多个线程中，setpos这个操作可能会发生相互干扰，导致页面出现混乱。
	#如果拿到锁的程序执行时间太长，会导致锁不够用。有些线程可能被饿死
	互斥系统 = Mutex.new

	#这个时间不宜过短，否则其他线程抢不到锁
	刷新延迟 = 争抢锁延迟 = 0.1

	Thread.new {
	  loop {|x|
	    互斥系统.synchronize {
	      Curses.setpos(1,2)
	      Curses.addstr("线程A #{a}")
	      Curses.refresh
	    }

	    sleep 刷新延迟
	  }
	}



	Thread.new {
	  loop {|x|
	  互斥系统.synchronize {
	    Curses.setpos(2,2)
	    Curses.addstr("线程B #{标识.更新形状}")
	    Curses.refresh
	  }

	  sleep 刷新延迟
	  } 
	}



	Thread.new {
	  loop {|x|
	  互斥系统.synchronize {
	    Curses.setpos(1,50)
	    Curses.addstr("               ")
	    Curses.setpos(1,50)
	    Curses.addstr("线程C #{等待.更新标识}")
	    Curses.refresh
	  }

	  sleep 刷新延迟
	  
	  } 
	}


	Thread.new {
	  loop {|x|
	  互斥系统.synchronize {
	    Curses.setpos(2,50)
	    Curses.addstr("线程D ")
	    Curses.refresh
	  }

	  sleep 刷新延迟
	  }
	}


	Curses.setpos(0,0)
	Curses.addstr("----------------------数据1-----------------------------")
	Curses.setpos(1,0)
	Curses.addstr("|")
	Curses.setpos(2,0)
	Curses.addstr("|")
	Curses.setpos(1,20)
	Curses.addstr("|")
	Curses.setpos(2,20)
	Curses.addstr("|")
	Curses.setpos(3,0)
	Curses.addstr("----------------------数据2----------------------------")


	sleep 1000*1000*1000

	Curses.close_screen	
rescue Exception => e
	puts e
	exit 1
end








=begin
def show_message(message=nil)
  height = 3######################Curses.lines/
  width  = Curses.cols ############Curses.cols/1                #message.length + 6
  top    =  0                  #  (Curses.lines - height) / 2
  left   =  0                 #(Curses.cols - width) / 2
  win = Curses::Window.new(height, width, top, left)
  #win.box("|", "*")
  win.setpos(1,1)
  message = $进度条.更新
  win.addstr(message)
  win.refresh
  #win.getch
  sleep 0.001
  win.close
end

def show_message2(message=nil)
  height = 3######################Curses.lines/
  width  = Curses.cols ############Curses.cols/1                #message.length + 6
  top    =  0                  #  (Curses.lines - height) / 2
  left   =  0                 #(Curses.cols - width) / 2
  win = Curses::Window.new(height, width, top, left)
  #win.box("|", "*")
  win.setpos(5,1)
  message = $进度条.更新
  win.addstr(message)
  win.refresh
  #win.getch
  sleep 0.001
  win.close
end


Curses.init_screen

1000.times {|x|
  #show_message 22
  #show_message2 22
}


Curses.close_screen



=end


=begin
loop {
 Curses.init_screen
begin
  Curses.crmode
  Curses.setpos((Curses.lines - 1) / 2, (Curses.cols - 11) / 2)
  Curses.addstr("Hit any key")
  Curses.refresh
  #Curses.getch
  sleep 1
  Curses.addstr("Hit any key2")
  #show_message("Hello, World!")
  Curses.refresh  
  sleep 1

ensure
  Curses.close_screen
end 
}
=end
