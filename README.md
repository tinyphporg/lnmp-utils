lnmp-utils
============

简介
===

>  Linux(CentOS7X_64) + Openresty/Nginx + Mysql + PHP + Redis + FastDFS一键安装包.   
>  经过实践检验，源码编译安装LNMP大型集群环境。   

> 项目主要应用于: [TinyPHP for Frameworks](https://github.com/tinyphporg/tinyphp.git) 的运行环境。   
>  地址: [https://github.com/tinyphporg/tinyphp.git](https://github.com/tinyphporg/tinyphp.git)    

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
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh
```

组件
=======

> 组件源: https://github.com/tinyphporg/lnmp-utils-components

+ [openresty(nginx+lua) 1.19.3.2](https://github.com/openresty/openresty.git)     Nginx+lua   
+ [mysql 8.0.27](http://cdn.mysql.com/Downloads/MySQL-8.0/mysql-8.0.27.tar.gz)  关系型数据库   
+ [php 7.3.33](http://www.php.net/)  PHP    
+ [php 7.4.26](http://www.php.net/)  PHP    
+ [php 8.1.0](http://www.php.net/)  PHP
  + redis
  + mongo
  + memcache     
+ [redis 6.2.6](http://www.redis.io/)  NOSQL   
+ [memcached 1.6.12 ](http://www.memcached.org/)  内存NOSQL   
+ [fastdfs 6.07](https://github.com/happyfish100/fastdfs)  分布式文件存储   
+ [lsyncd](https://github.com/lsyncd/lsyncd)  文件实时同步   
+ [node.js 16.0.1](https://nodejs.org/)   

安装组件   
---

```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c openresty mysql php redis memecached fastdfs lsyncd node
```

> openresty/nginx 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c openresty -o fdfs proxy
   #-o fdfs 安装fastdfs模块 upload模块
   #-o proxy 安装https的正向代理模块 proxy_connect
```
> mysql 8 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c mysql
```
> php 7.3/7.4/8.1 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c php
```

> nginx/openresty 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c openresty
```


> redis 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c redis
```

> memcached 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c memcached
```
> node.js 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c node
```
> lsync 文件实时同步 一键安装
```shell
   git clone https://github.com/tinyphporg/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c lsyncd
```
