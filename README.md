lnmp-utils README
============

lnmp一键安装
===
> centos7x下一键安装lnmp(linux+nginx+mysql+php)环境

```shell
   git clone https://github.com/tinycn/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -m lnmp
```
简介
===

>  Linux(CentOS7X_64) + Openresty/Nginx + Mysql + PHP + Redis一键安装包.

>  已经过实践检验，可组成支撑日PV10级别的LNMP大型集群环境。
  
>  主要服务于[TinyPHP for Frameworks](https://github.com/tinycn/tinyphp.git)这款PHP轻量级框架的生产环境,
  
> 项目地址: [https://github.com/tinycn/tinyphp.git](https://github.com/tinycn/tinyphp.git)

>  安装方式: 源码编译.

>  优势: 注重性能，简洁高效，适合开发/生产环境的早期架构预研和部署。

>  推荐部署系统: CentOS 7.x 64 minimal

>  推荐部署的基础硬件:
    + CPU 4/8核，
    + 内存 16/32G，
    + 硬盘 SSD + HDD。

组件清单
=======

+ openresty(nginx+lua) 
    + 1.15.8.2 
    + [https://github.com/openresty/openresty.git](https://github.com/openresty/openresty.git)
    + High Performance Web Platform Based on Nginx and LuaJIT

+ mysql                8.0.18 https://github.com/mysql/mysql-server.git
       MySQL Server, the worlds most popular open source database, and MySQL Cluster, a real-time, open source transactional database.

+ php                  7.3.10 http://php.net
       PHP语言环境

+ redis                5.0.7 http://redis.io/
       可持久化的内存NOSQL

+ memcached            1.5.19 http://www.memcached.org/
       纯内存NOSQL

+ fastdfs              6.01 https://github.com/happyfish100/fastdfs.git
       分布式小文件存储

+ lsyncd
       CentOS下文件实时同步组件

组件源与扩展
=======
公共组件源:  https://github.com/tinycn/lnmp-utils-components.git

添加或更改组件源代理

```shell
vi ./install.conf
#GITHUB_PROXY
GITHUB_PROXY="https://ghproxy.com/"
```
可以自定义扩展组件


下载到本地
=======
```shell
   git clone https://github.com/tinycn/lnmp-utils.git
```

组件安装
=======
```shell
   git clone https://github.com/tinycn/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -c php redis mysql memcached openresty
```

模块安装
=======
```shell
   git clone https://github.com/tinycn/lnmp-utils.git
   cd lnmp-utils
   ./install.sh -m lnmp
```