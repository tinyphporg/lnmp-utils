#!/bin/bash

PATH=/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/sbin:~/bin
export PATH

if [ $(id -u) != '0' ]; then
	echo '必须以root身份运行该安装脚本!'
	exit
fi

if [ ! -f /etc/centos-release ] || [ `cat /etc/centos-release|grep -e "CentOS Linux release 7\." -e "CentOS Linux release 8\."  |wc -l` -eq "0" ];then
	echo '必须运行在CentOS7 OR CentOS8系统环境!'
	exit
fi

SYSTEM_VERSION="centos7"
if [ `cat /etc/centos-release|grep -e "CentOS Linux release 8\."|wc -l` -gt 0 ]; then
	SYSTEM_VERSION="centos8"
fi

#lnmp-utils

#global setting
#数据目录
DATA_DIR=/data/

#安装目录
INSTALL_DIR=/usr/local/

#源地址
SOURCE_SYSTEM=$SYSTEM_VERSION

#SOURCE_URL="https://raw.githubusercontent.com/zeroainet/lnmp-utils-components/master/";
SOURCE_URL="https://zeroai.coding.net/p/lnmp-utils-components/d/lmnp-utils-components/git/raw/master/"


#获取当前目录名
CURRENT_DIR=$(cd `dirname $0`; pwd)


inarray() {
    local _var=$1
    local _arr=$2
    if [[ "${_arr[@]/$_var/}" != "${_arr[@]}" ]];then
        echo "1"
    else
        echo "0"
    fi
}

showhelp(){
	echo "ZeroAI-utils For CentOS 7 Beta 1.0"
	echo -e "From:   https://github.com/zeroainet/zeroai-utils"
	echo "---------------------"
	echo "-h|--help            可阅读详细帮助"
	echo "-q|--quiet           静默安装"
	echo "-c|--component=xxx   可直接安装组件 多个组件用,分隔!"
	echo "-m|--mode=xxx        可直接安装模块"
	echo "-o|--option          附加参数"
	echo "-b|--build           创建内容"
	echo "--no-clear           不清除临时文件夹"
	exit
}

checkdir(){
	local _dirs=('.' './' '../' '..' '/')
	if [ "${1}" = "" ] || [ `inarray "${1}" "${_dirs[*]}"` = "1" ] || [ -f "${1}" ];then
		echo "${1}不能为空, 已存在的文件, 或('.' './' '../' '..' '/')中的一个。"
		exit
	fi
}

optinit(){
	local _tmpopt=`getopt -o "qo:c:m:h" -l "component:,option:,mode:,quiet,help" -n "$0" -- "$@"`
	if [ "$?" != "0" ];then
		echo && showhelp
	fi
	set -- $_tmpopt
}


optinit

CURRENT_IS_QUIET="0"
CURRENT_IS_NO_CLEAR="0"
while [ -n "$1" ]; do
    case "${1}" in
    	-q|--quiet)
    		shift;
    		CURRENT_IS_QUIET='1'
    		;;
    	-c|--component)
    		shift;
    		CURRENT_COMPONENTS=`echo ${1//\'/}|tr ',' " "`
    		shift;
    		;;
        -m|--mode)
        	shift;
        	CURRENT_MODES=`echo ${1//\'/}|tr ',' " "`
        	shift;
        	;;
        -o)
        	shift;
        	CURRENT_OPTIONS=`echo ${1//\'/}|tr ',' " "`
        	shift;
        	;;
        -h|--help)
        	shift;
    		showhelp;
        	;;
        -b|--build)
        	shift;
        	CURRENT_IS_BUILD="1"
        	;;
        --no-clear)
        	shift;
        	CURRENT_IS_NO_CLEAR="1"
        	;;
        --)
        	shift;
        	break;
        	;;
    esac
done

CPU_NUM=`cat /proc/cpuinfo|grep "model name"|wc -l`

if [ $CPU_NUM -gt 4 ];then
CPU_NUM=4
fi

if [ -f "$CURRENT_DIR/install.conf" ];then
	source $CURRENT_DIR/install.conf
fi

#curl "${SOURCE_URL}/pkg.cnf" -i

checkdir "${INSTALL_DIR}"
checkdir "${DATA_DIR}"


#资源包的存放目录
PKG_DIR=$CURRENT_DIR/pkg/
#资源包的模块目录
PKG_MODULE_DIR=${PKG_DIR}module/
#资源包的组件目录
PKG_COMPONENT_DIR=${PKG_DIR}component/



#临时解压与安装目录
TMP_DIR=/tmp/zeroai/zeroai-utils/
#组件临时目录
TMP_COM_DIR=${TMP_DIR}component/
#模块临时目录
TMP_MOD_DIR=${TMP_DIR}module/
#资源包的临时目录
TMP_PKG_DIR=${TMP_DIR}pkg/
#资源的存放目录
SOURCE_DIR=${TMP_DIR}source/

if [[ "${CURRENT_IS_BUILD}" == "1" ]];then
	SOURCE_DIR=$CURRENT_DIR/build/
fi

#资源的模块存放目录
SOURCE_MODULE_DIR=${SOURCE_DIR}module/
#资源的组件存放目录
SOURCE_COMPONENT_DIR=${SOURCE_DIR}component/

#默认安装目录
DEFAULT_INSTALL_DIR=/usr/local/


#网站目录
DATA_WEB_DIR=${DATA_DIR}web/
#数据库目录
DATA_DB_DIR=${DATA_DIR}db/
#script文件路径
DATA_SCRIPT_DIR=${DATA_DIR}script/
#conf文件路径
DATA_CONF_DIR=${DATA_DIR}conf/
#bak文件路径
DATA_BAK_DIR=${DATA_DIR}bak/
#LOG存放目录
DATA_LOG_DIR=${DATA_DIR}log/
#DFS存储目录
DATA_DFS_DIR=${DATA_DIR}dfs/
#缓存文件路径
DATA_CACHE_DIR=${DATA_DIR}cache/

#LOG文件路径
DATA_LOG_FILE=${DATA_DIR}install.log

#模块目录
MOD_DIR=""
#模块名称
MOD_NAME=""
#模块安装文件
MOD_INSTALL_SCRIPT=""

#模块安装包目录
MOD_PACKAGE_DIR=""

#模块配置目录
MOD_CONF_DIR=""

#组件目录
COM_DIR=""

#组件名称
COM_NAME=""

#组件源码文件
COM_SOURCE_FILE=""

#组件安装目录
COM_INSTALL_DIR=""

#组件安装脚本
COM_INSTALL_SCRIPT=""

#组件安装包目录
COM_PACKAGE_DIR=""

#组件配置目录
COM_CONF_DIR=""

#组件的配置目录
COM_DATA_CONF_DIR=""

#组件的DB目录
COM_DATA_DB_DIR=""


#组件的脚本目录
COM_DATA_SCRIPT_DIR=""

#组件的日志目录
COM_DATA_LOG_DIR=""


#fun list
#输出日志
outlog(){
	local _d=`date +"%Y-%m-%d %H:%M:%S"`
	echo -e "$_d $1">> $DATA_LOG_FILE
}
#临时文件夹清理
tmp_clear() {
	if [ "$TMP_DIR" != "" ] && [ -d "$TMP_DIR" ];then
    	rm -rf $TMP_DIR/*
	fi
}

#错误退出
error(){
        echo -e "\033[0;31;1m Zeroai-utils Installer Error:\033[0m\n  ${1}";
	outlog "Error: $1"
	tmp_clear
        exit 1;
}

#添加用户
user_add(){
	local _g=$1
	local _u=$2

	if [ "$_g" == "" ];then
		return;
	fi

	if [ "$_u" == "" ];then
		_u=$_g;
	fi

	if [ `cat /etc/group|grep "^${_g}:"|wc -l` -eq "0" ];then
		groupadd $_g
	fi
    if [ `cat /etc/passwd|grep "^$_u:"|wc -l` -eq "0" ];then
                useradd -g $_g  $_u
    fi

}

#生成目录
createdir(){
        local _p;
	if [ "$1" = "" ];then
		return;
	fi
        for _p in $@;
        do
        	if [ -d "$_p" ];then
			continue;
		fi
		mkdir -p -m 777 $_p;
        done
}

#安装yum package
yum_install(){
	local _i="";
	local _wpn=`yum list installed`;
        for _i in $@; do
			if [ `echo $_wpn|tr " " "\n"|grep -e "^${_i}"|wc -l` -eq "0" ];then
				echo $_i
				yum -y install $_i;
			fi
        done
}

yum_uninstall() {
	local _i='';
	local _wpn=`yum list installed`;
    for _i in $@;
    do
        if [ `echo $_wpn|tr " " "\n"|grep -e "^${_i}"|wc -l` -gt "0" ];then
        	yum -y remove $_i
        fi
	done
}

#根据端口删除进程

killport(){
        if [ ! "$1" ];then
                return;
        fi
        local _pn= `netstat -anp|grep ":$1\s"|awk '{print $7}'|awk -F'/' '{print $2}'|awk -F':' '{print $1}'`
        if [ "$_PN" != "" ];then
                killall -9 $_pn
        fi
}
#必须组件
require(){
	com_install "$1";
}

#安装
install(){
        if [ "$CURRENT_MODE" = "c" ];then
                com_install "$1"
        elif [ "$CURRENT_MODE" = "m" ];then
                mod_install "$1"
        fi
}

#初始化组件临时文件
com_tmp_init(){
		echo "删除组件的临时文件"
        if [ "$TMP_COM_DIR" != "" ];then
                if [ ! -d $TMP_COM_DIR ];then
                        createdir $TMP_COM_DIR
                else
                        chmod -R 777 $TMP_COM_DIR
                fi
                rm -rf  $TMP_COM_DIR"*"
        fi
}

_SOURCE_PKG_CONF=""
pkg_conf_get(){
	echo $SOURCE_URL"pkg.cnf"
	if [ "${_SOURCE_PKG_CONF}" == "" ];then
		echo
		if [ `curl -s -i $SOURCE_URL"pkg.cnf"|grep 'HTTP/1.1 200 OK'|wc -l` == '0' ];then
			error "url connect timeout! ${SOURCE_URL}"
		fi
		_SOURCE_PKG_CONF=`curl -s $SOURCE_URL"pkg.cnf"|tr "\n" " "`
	fi
	echo -e ${_SOURCE_PKG_CONF[*]}|tr " " "\n"|grep -i "centos7"
}

com_source_get() {
	local _cname=$1
	local _cdir=$2
	local cName="${SOURCE_SYSTEM}-component-${_cname}"
	local _pkgfile="${PKG_COMPONENT_DIR}${cName}.zip"

	if [ ! -f "${_pkgfile}" ];then
		pkg_conf_get
		if [ `pkg_conf_get|grep ${cName}|wc -l` == "0" ];then
			return
		fi

		local _tmpDir=$TMP_PKG_DIR"$cName/"
		if [ -e "$_tmpDir" ];then
			if [ ! -d "$_tmpDir" ];then
				rm -rf $_tmpDir
			fi
			cd $_tmpDir && rm -rf *
		else
			mkdir -m 777 -p $_tmpDir
		fi

		local _pkgurl="${SOURCE_URL}pkg/"
		local _zipfiles=(`curl -s ${_pkgurl}${cName}".cnf"|tr "\n" " "`)
		cd $_tmpDir
		#wget ${_pkgurl}${cName}".cnf"
		echo "" > ${cName}".cnf"
		for _zname in "${_zipfiles[@]}"
		do
			_zurl="${_pkgurl}${_zname}"
			echo ${_zurl} >> ${cName}.cnf
		done
		wget -i ${cName}".cnf"
		zip ${cName}.zip -s=0 --out $_pkgfile
	fi
	unzip $_pkgfile -d $_cdir
}

#安装组件
com_install(){

        local _com;
        for _com in $1;
        do

                COM_NAME=$_com
                COM_DIR="$SOURCE_COMPONENT_DIR$_com/"
                COM_PACKAGE_DIR="${COM_DIR}package/"
                COM_SOURCE_FILE=""
                COM_CONF_DIR="${COM_DIR}conf/"
                COM_INSTALL_SCRIPT="${COM_DIR}install.sh"
                COM_INSTALL_DIR="${INSTALL_DIR}$_com/"
                COM_DATA_CONF_DIR="${DATA_CONF_DIR}$_com/"
                COM_DATA_DB_DIR="${DATA_DB_DIR}$_com/"
                COM_DATA_SCRIPT_DIR="${DATA_SCRIPT_DIR}$_com/"
                COM_DATA_LOG_DIR="${DATA_LOG_DIR}$_com/"
                COM_DATA_CACHE_DIR="${DATA_CACHE_DIR}$_com/"
                if [ ! -d $COM_DIR ];then
                		com_source_get "$COM_NAME" "$SOURCE_COMPONENT_DIR"
                		if [ ! -d $COM_DIR ];then
                        	error "组件${_com}安装失败,目录${COM_DIR}不存在!"
                        fi
                fi

                if [ ! -f $COM_INSTALL_FILE ]; then
                        error "组件${_com}安装失败,${COM_INSTALL_FILE}不存在!"
                fi

                com_tmp_init

          	echo "安装组件包：${_com}开始";
          	cd $CURRENT_DIR
                . $COM_INSTALL_SCRIPT
                echo "安装组件包：${_com}结束";
                sleep 2


                COM_NAME=$_com
                COM_DIR=""
				COM_PACKAGE_DIR=""
				COM_SOURCE_FILE=""
				COM_CONF_DIR=""
				COM_INSTALL_SCRIPT=""
				COM_INSTALL_DIR=""
                COM_DATA_CONF_DIR=""
                COM_DATA_DB_DIR=""
                COM_DATA_SCRIPT_DIR=""
                COM_DATA_LOG_DIR=""
                COM_DATA_CACHE_DIR=""
        done

        com_tmp_init

}


#解压组件的tar文件
com_untar(){
        tar zxvf $1 -C $TMP_COM_DIR >/dev/null
}

#解压组件的zip文件
com_unzip() {
        unzip  -u $1  -d $TMP_COM_DIR>/dev/null
}

com_unbz2(){
        tar jxvf $1 -C $TMP_COM_DIR >/dev/null
}

com_init(){
		local _isdelete=""
        COM_SOURCE_FILE="${COM_PACKAGE_DIR}$1"
        if [ -d $COM_INSTALL_DIR ]; then
                echo -n "${COM_NAME}已经安装，是否删除(y/n):"
                read _isdelete
                if [ "${_isdelete}" = "y" ] || [ "${_isdelete}" = "Y" ];then
                	#rm -rf $COM_INSTALL_DIR
                	echo "aaa"
                else
                	error "${COM_NAME} is stopped and exit!"
                fi
        fi
        if [ ! -f $COM_SOURCE_FILE ]; then
                error "$COM_NAME安装失败, $COM_SOURCE_FILE不存在!"
        fi
}

#组件包检测
com_pkg_check() {
	for _pkg in "$@"
	do
		if [ ! -f "$_pkg" ]; then
        	error "${COM_NAME}安装失败,${_pkg}不存在!"
		fi
	done
}

com_file_replace(){
	local _s=$1
	local _t=$2
	local _path=$3
	_t=${_t//\//\\\/}
	sed -i "s/${_s}/${_t}/g" $_path
}
com_replace(){
	for _path in "$@"
	do
		if [ ! -f "$_path" ];then
			error "${COM_NAME}安装失败,${_path}不存在!"
		fi
		com_file_replace '{COM_DATA_CONF_DIR}' "${COM_DATA_CONF_DIR}" $_path
		com_file_replace '{COM_DATA_DB_DIR}' "${COM_DATA_DB_DIR}" $_path
		com_file_replace '{COM_INSTALL_DIR}' "${COM_INSTALL_DIR}" $_path
		com_file_replace '{COM_DATA_CACHE_DIR}' "${COM_DATA_CACHE_DIR}" $_path
		com_file_replace '{COM_DATA_SCRIPT_DIR}' "${COM_DATA_SCRIPT_DIR}" $_path
		com_file_replace '{COM_DATA_LOG_DIR}' "${COM_DATA_LOG_DIR}" $_path
		com_file_replace '{CPU_NUM}' "${CPU_NUM}" $_path
	done
}

com_install_test(){
	if [ ! -e "${COM_INSTALL_DIR}" ];then
		error "${COM_NAME} installation failed: the installation path ${COM_INSTALL_DIR} is not exists!"
	fi

	for _path in $@
	do
		if [ ! -e "$_path" ];then
			error "${COM_NAME} installation failed: the installation path ${_path} is not exists!"
		fi
	done
}
#初始化模块临时文件
mod_tmp_init(){
        if [ "$TMP_MOD_DIR" != "" ];then
                if [ ! -d $TMP_MOD_DIR ];then
                        createdir $TMP_MOD_DIR
                else
                        chmod -R 777 $TMP_MOD_DIR
                fi
                rm -rf  $TMP_MOD_DIR"*"
        fi
}

#安装模块
mod_install(){
        local _mod;
        for _mod in $1;
        do
                MOD_DIR="${SOURCE_MODULE_DIR}$_mod/"
                MOD_NAME=$_mod
                MOD_PACKAGE_DIR="${MOD_DIR}package/"
                MOD_CONF_DIR="${MOD_DIR}conf/"
                MOD_INSTALL_SCRIPT="${SOURCE_MODULE_DIR}$_mod/install.sh"

                if [ ! -d $MOD_DIR ];then
                        error "模块${_mod}安装失败,目录${MOD_DIR}不存在!"
                fi

                if [ ! -f $MOD_INSTALL_FILE ]; then
                        error "模块${_mod}安装失败,${MOD_INSTALL_FILE}不存在!"
                fi

                mod_tmp_init

                echo "安装模块：${_mod}开始";
                cd $CURRENT_DIR
                . $MOD_INSTALL_SCRIPT
                echo "安装模块：${_mod}结束";
                sleep 2

                MOD_DIR=""
                MOD_NAME=""
                MOD_PACKAGE_DIR=""
                MOD_CONF_DIR=""
                MOD_INSTALL_SCRIPT=""
        done
        mod_tmp_init
}


#解压组件的tar文件
mod_untar(){
        tar zxvf $1 -C $TMP_MOD_DIR >/dev/null
}

#解压组件的zip文件
mod_unzip() {
        unzip -f $1 -d $TMP_MOD_DIR >/dev/null
}
mod_unbz2(){
        tar jxvf $1 -C $TMP_MOD_DIR >/dev/null
}

#是否有某个参数
hasoption(){
	inarray "${1}" "${CURRENT_OPTIONS[*]}"
}



#创建data文件夹
createdir $DATA_DIR $DATA_BAK_DIR

#创建PKG文件夹
createdir $PKG_DIR $PKG_COMPONENT_DIR $PKG_MODULE_DIR

#创建SOURCE文件夹
createdir $SOURCE_DIR $SOURCE_COMPONENT_DIR $SOURCE_MODULE_DIR

#需要备份的data文件夹路径
createdir $DATA_BAK_DIR $DATA_WEB_DIR $DATA_DB_DIR $DATA_SCRIPT_DIR $DATA_CONF_DIR

if [ "$CURRENT_IS_QUIET" = '0' ];then

    #设置时区
    rm -f /etc/localtime
    cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

    #关闭selinux
    if [ -s /etc/selinux/config ]; then
	    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    fi


    #加载基础库
    if [ ! -f /etc/ld.so.conf.d/zeroai-utils.conf ];then
    cat >> /etc/ld.so.conf.d/zeroai-utils.conf <<EOT
/usr/local/lib
/usr/local/lib64
EOT
    ldconfig -v
    fi

    #优化网络参数
    grep "^#patch by zeroai-utils$" /etc/sysctl.conf >/dev/null
    if [ $? != 0 ]; then

        cat >>/etc/sysctl.conf<<EOF
#patch by zeroai-utils
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 8192 4336600 873200
net.ipv4.tcp_rmem = 32768 4336600 873200
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65000
vm.zone_reclaim_mode = 1
EOF
        sysctl -p >>/dev/null 2>&1
    fi


    #优化文件描述符
    grep "^#patch by zeroai-utils$" /etc/security/limits.conf >/dev/null
    if [ $? != 0 ]; then

        cat >>/etc/security/limits.conf<<EOF
#patch by zeroai-utils
*               soft     nproc         65536
*               hard     nproc         65536

*               soft     nofile         102400
*               hard     nofile         102400
EOF

    fi
    ulimit -n 102400

	#添加用户
	user_add www www

	#安装必须的包
	yum_install make gd-devel flex bison file libtool libtool-libs autoconf ntp ntpdate net-snmp-devel  readline-devel net-snmp net-snmp-utils psmisc net-tools iptraf ncurses-devel  iptraf wget curl patch make gcc gcc-c++  kernel-devel unzip zip pigz
	yum_install pcre-devel openssl-devel

	#同步时间
	ntpdate cn.pool.ntp.org
	hwclock --systohc
fi

com_install "${CURRENT_COMPONENTS[*]}"


mod_install "${CURRENT_MODULES[*]}"

#清理临时文件夹
if [ "${CURRENT_IS_NO_CLEAR}" == '0' ];then
	tmp_clear
fi
