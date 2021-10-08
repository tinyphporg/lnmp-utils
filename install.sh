#!/bin/bash

PATH=/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/sbin:~/bin
export PATH

if [ $(id -u) != '0' ]; then
	echo '必须以root身份运行该安装脚本!'
	exit
fi

#global setting
#数据目录
DATA_DIR=/data/

#安装目录
INSTALL_DIR=/usr/local/

#系统名 默认为centos
SYSTEM_NAME="centos"
SYSTEM_VERSION="centos.7x"
SOURCE_SYSTEM=$SYSTEM_VERSION
SOURCE_URL="https://raw.githubusercontent.com/saasjit/lnmp-utils-components/master/";

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
	echo "lnmp-utils For CentOS.7x.x86_64"
	echo -e "From:   https://github.com/saasjit/lnmp-utils"
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


#option init
CURRENT_IS_QUIET="0"
CURRENT_IS_NO_CLEAR="0"
CURRENT_COMPONENTS=()
CURRENT_MODES=()
CURRENT_OPTIONS=()

optinit
while [ -n "$1" ]; do
    case "${1}" in
    	-q|--quiet)
    		shift;
    		CURRENT_IS_QUIET='1'
    		;;
    	-c|--component)
    		shift;
    		while [ "$1" != "" ] && [ "${1:0:1}" != "-" ]; do
    			CURRENT_COMPONENTS[${#CURRENT_COMPONENTS}]=$1
    			shift;
    		done
    		;;
        -m|--mode)
    		shift;
    		while [ "$1" != "" ] && [ "${1:0:1}" != "-" ]; do
    			CURRENT_MODES[${#CURRENT_MODES}]=$1
    			shift;
    		done
        	;;
        -o)
    		shift;
    		while [ "$1" != "" ] && [ "${1:0:1}" != "-" ]; do
    			CURRENT_OPTIONS[${#CURRENT_OPTIONS}]=$1
    			shift;
    		done
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
        *)
        	shift;
        	;;
    esac
done

if [ -f "$CURRENT_DIR/install.conf" ];then
	source $CURRENT_DIR/install.conf
fi

if [ "$GITHUB_PROXY" != "" ]; then
	SOURCE_URL=$GITHUB_PROXY$SOURCE_URL
fi

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

pkg_install() {
	if [ "$SYSTEM_NAME" == 'centos' ]; then
		yum_install $@;
	fi
}

pkg_uninstall() {
	if [ "$SYSTEM_NAME" == 'centos' ]; then
		yum_uninstall $@;
	fi
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
	com_install "$*";
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
		
		if [ `curl -s -i $SOURCE_URL"pkg.cnf"|grep -e 'HTTP/1.1 200 OK' -e 'HTTP/2 200' |wc -l` == '0' ];then
			error "url connect timeout! ${SOURCE_URL}"
		fi
		_SOURCE_PKG_CONF=`curl -s $SOURCE_URL"pkg.cnf"|tr "\n" " "`
	fi
	echo -e ${_SOURCE_PKG_CONF[*]}|tr " " "\n"
}

com_source_get() {
	local _cname=$1
	local _cdir=$2
	local cName="linux-component-${_cname}"
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
                COM_INSTALL_SCRIPT="${COM_DIR}install.${SYSTEM_VERSION}.sh"
                COM_INSTALL_DEFAULT_SCRIPT="${COM_DIR}install.sh"
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
				
                if [ ! -f $COM_INSTALL_SCRIPT ] && [ ! -f $COM_INSTALL_DEFAULT_SCRIPT ]; then
                        error "组件${_com}安装失败,${COM_INSTALL_SCRIPT} && ${COM_INSTALL_DEFAULT_SCRIPT}不存在!"
                fi
                
                com_tmp_init

          	echo "安装组件包：${_com}开始";
          	cd $CURRENT_DIR
          		
          		if [ -f $COM_INSTALL_SCRIPT ]; then
                	. $COM_INSTALL_SCRIPT
                elif [ -f $COM_INSTALL_DEFAULT_SCRIPT ]; then
                	. $COM_INSTALL_DEFAULT_SCRIPT
                fi
                
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

#解压组件的tar文件
com_untarxz(){
        tar xvf $1 -C $TMP_COM_DIR >/dev/null
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

#最大编译内核
CPU_NUM=`cat /proc/cpuinfo|grep "model name"|wc -l`
if [ -n "$(echo $MAKE_MAX_CPU_NAME| sed -n "/^[0-9]\+$/p")" ] && [ $CPU_NUM -gt "$MAKE_MAX_CPU_NAME" ]; then
	CPU_NUM=$MAKE_MAX_CPU_NAME
fi

#创建data文件夹
createdir $DATA_DIR $DATA_BAK_DIR

#创建PKG文件夹
createdir $PKG_DIR $PKG_COMPONENT_DIR $PKG_MODULE_DIR

#创建SOURCE文件夹
createdir $SOURCE_DIR $SOURCE_COMPONENT_DIR $SOURCE_MODULE_DIR

#需要备份的data文件夹路径
createdir $DATA_BAK_DIR $DATA_WEB_DIR $DATA_DB_DIR $DATA_SCRIPT_DIR $DATA_CONF_DIR

#加载系统指定初始化脚本
if [ -f /etc/centos-release ]; then
	SYSTEM_NAME="centos"
	SYSTEM_VERSION="centos.7x"
fi

INSTALL_SYSTEM_SCRIPT="${CURRENT_DIR}/init.${SYSTEM_NAME}.sh"
echo $INSTALL_SYSTEM_SCRIPT

if [ -f $INSTALL_SYSTEM_SCRIPT ]; then
. $INSTALL_SYSTEM_SCRIPT
fi

com_install "${CURRENT_COMPONENTS[*]}"

mod_install "${CURRENT_MODES[*]}"

#清理临时文件夹
if [ "${CURRENT_IS_NO_CLEAR}" == '0' ];then
	tmp_clear
fi
