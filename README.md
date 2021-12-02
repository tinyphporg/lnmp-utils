lnmp-utils
============

简介
===

>  Linux(CentOS7X_64) + Openresty/Nginx + Mysql + PHP + Redis + FastDFS一键安装包.   
>  经过实践检验，源码编译安装LNMP大型集群环境。   
>  主要服务于[TinyPHP for Frameworks](https://github.com/saasjit/tinyphp.git) 项目地址: [https://github.com/saasjit/tinyphp.git](https://github.com/saasjit/tinyphp.git)    

安装
===
- 安装方式: 源码编译, 适合开发/生产环境的早期架构预研和部署。   
- 系统: CentOS 7.x x64 minimal。  
 
+ 基础硬件要求:
  - CPU： 4核，  
  - 内存：16G，  
  - 硬盘：128G以上SSD/HDD。 
   
lnmp一键安装  
---- 
```shell
   git clone https://github.com/saasjit/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -m lnmp
```

组件
=======

> 组件源: https://github.com/saasjit/lnmp-utils-components

+ [openresty(nginx+lua) 1.15.8.2](https://github.com/openresty/openresty.git)     Nginx+lua   
+ [mysql 8.0.18](http://cdn.mysql.com/Downloads/MySQL-8.0/mysql-8.0.18.tar.gz)  关系型数据库   
+ [php 7.3.10](http://cn2.php.net/distributions/php-5.6.27.tar.gz)  PHP    
+ [redis 5.0.7](http://download.redis.io/releases/redis-5.0.7.tar.gz)  NOSQL   
+ [memcached 1.5.19 ](http://www.memcached.org/files/memcached-1.5.19.tar.gz)  内存NOSQL   
+ [fastdfs 6.07](https://github.com/happyfish100/fastdfs)  分布式文件存储   
+ [lsyncd](https://github.com/lsyncd/lsyncd)  文件实时同步   
+ [node.js 16.0.1](https://nodejs.org/)   

安装组件   
---
```shell
   git clone https://github.com/saasjit/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c openresty mysql php redis memecached fastdfs lsyncd node
```
