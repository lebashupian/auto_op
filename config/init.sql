-- 注意,ruby是以 分号 为分隔符来读取文件的，所以建表语句末尾一定要加上分号
CREATE TABLE `hostinfo` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `ip` varchar(20) NOT NULL,
  `username` varchar(50) DEFAULT NULL,
  `password` varchar(50) DEFAULT NULL,
  `port` int(6) NOT NULL DEFAULT '22',
  `grp` varchar(30) NOT NULL DEFAULT '.all.',
  `used` varchar(6) NOT NULL DEFAULT 'Y',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8;
--
CREATE TABLE `iptabs` (
  `ip地址` varchar(20) DEFAULT NULL,
  `国家` varchar(20) DEFAULT NULL,
  `地区` varchar(20) DEFAULT NULL,
  `城市` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
--
CREATE TABLE `log_info` (
  `hostip` varchar(20) NOT NULL,
  `type` varchar(20) NOT NULL,
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `log_path` varchar(1024) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8
