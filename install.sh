#!/bin/bash

PATH=/usr/local/bin:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/sbin:~/bin
export PATH

if [ $(id -u) != '0' ]; then
	echo 'Must be setuid root'
	exit
fi

DATA_DIR=/data/
INSTALL_DIR=/usr/local/

SYSTEM_NAME="centos"
SYSTEM_VERSION="centos.7x"

#source
IS_SOURCE=1
SOURCE_SYSTEM=$SYSTEM_VERSION
SOURCE_GIT_URL="https://github.com/opensaasnet/lnmp-utils-components.git"
SOURCE_URL="https://raw.githubusercontent.com/opensaasnet/lnmp-utils-components/master/";

# define functions
inarray() {
    local var=$1
    local arr=$2
    if [[ "${arr[@]/$var/}" != "${arr[@]}" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

showhelp(){
	echo "CentOS 7.X lnmp-utils"
    echo "---------------------"
    echo "component list:"
	echo "lnmp: openresty(nginx+lua) mysql  php"
	echo "nosql:   redis memcached"
	echo "dfs:     fastdfs"
	echo "node.js: node"
	echo "From: https://github.com/opensaasnet/lnmp-utils"
    echo "---------------------"
    echo "module list:"	
    echo "lnmp"
	echo "---------------------"
	echo "-h|--help            Help"
	echo "-q|--quiet           Silent installation mode"
	echo "-c|--component=xxx   Install components"
	echo "                     ./install.sh -c mysql php redis openresty node fastdfs ..."
	echo "-m|--mode=xxx        Install modules"
	echo "-o|--option          Options for installing components"
	echo "                     ./install.sh -c openresty -o fdfs proxy"
	echo "-b|--build           Build folder for custom component development(github.com访问不了时使用)."
	echo "--no-clear           Do not clean up the installation folder. "
	exit
}

checkdir(){
	local dirs=('.' './' '../' '..' '/')
	if [ "${1}" = "" ] || [ `inarray "${1}" "${dirs[*]}"` = "1" ] || [ -f "${1}" ]; then
		echo "Invalid dirname:${1}"
		exit
	fi
}

optinit(){
	local tmpopt=`getopt -o "qo:c:m:h" -l "component:,option:,mode:,quiet,help" -n "$0" -- "$@"`
	set -- $tmpopt
}

#options
CURRENT_DIR=$(cd `dirname $0`; pwd)
CURRENT_IS_QUIET="0"
CURRENT_IS_NO_CLEAR="0"
CURRENT_COMPONENTS=()
CURRENT_MODULES=()
CURRENT_OPTIONS=()
BUILD_DIR=$CURRENT_DIR"/build"
GIT_DIR=$CURRENT_DIR"/lnmp-utils-components"
optinit
while [ -n "$1" ]; do
    case "${1}" in
    	-q|--quiet)
    		shift;
    		CURRENT_IS_QUIET='1'
    		;;
    	-c|--component)
    		shift;
    		while [ "${1}" != "" ] && [ "${1:0:1}" != "-" ]; do
    			CURRENT_COMPONENTS[${#CURRENT_COMPONENTS}]=$1
    			shift;
    		done
    		;;
        -m|--mode)
    		shift;
    		while [ "${1}" != "" ] && [ "${1:0:1}" != "-" ]; do
    			CURRENT_MODULES[${#CURRENT_MODULES}]=$1
    			shift;
    		done
        	;;
        -o)
    		shift;
    		while [ "${1}" != "" ] && [ "${1:0:1}" != "-" ]; do
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

if [ -f "${CURRENT_DIR}/install.conf" ]; then
	source $CURRENT_DIR/install.conf
fi

checkdir "${INSTALL_DIR}"
checkdir "${DATA_DIR}"

#package setting
PKG_DIR=$CURRENT_DIR/pkg/
PKG_MODULE_DIR=${PKG_DIR}module/
PKG_COMPONENT_DIR=${PKG_DIR}component/
PKG_SOURCE_CONF=""

#tmp dir
TMP_RAND=$[$RANDOM%10000+30000]
TMP_DIR=/tmp/opensaasnet/lnmp-utils/${TMP_RAND}/
TMP_COM_DIR=${TMP_DIR}component/
TMP_MOD_DIR=${TMP_DIR}module/
TMP_PKG_DIR=${TMP_DIR}pkg/

# source
SOURCE_DIR=${TMP_DIR}source/
if [[ "${CURRENT_IS_BUILD}" == "1" ]];then
	SOURCE_DIR=$BUILD_DIR/linux/
	if [ ! -d "$SOURCE_DIR" ];then
		if [ ! -d $GIT_DIR ];then
			mkdir -p $GIT_DIR
		fi
		if [ ! -f "$GIT_DIR/pkg.cnf" ] || [ ! -d "$GIT_DIR/pkg" ];then
			git clone $SOURCE_GIT_URL
		fi
		if [ ! -f "$GIT_DIR/pkg.cnf" ] || [ ! -d "$GIT_DIR/pkg" ];then
			echo "git clone faild:"$SOURCE_GIT_URL
			exit
		fi
		
		
	fi
fi

SOURCE_MODULE_DIR=${SOURCE_DIR}module/
SOURCE_COMPONENT_DIR=${SOURCE_DIR}component/

# data setting
#DATA_DIR=/data
DATA_WEB_DIR=${DATA_DIR}web/
DATA_DB_DIR=${DATA_DIR}db/
DATA_SCRIPT_DIR=${DATA_DIR}script/
DATA_CONF_DIR=${DATA_DIR}conf/
DATA_BAK_DIR=${DATA_DIR}bak/
DATA_LOG_DIR=${DATA_DIR}log/
DATA_DFS_DIR=${DATA_DIR}dfs/
DATA_CACHE_DIR=${DATA_DIR}cache/
DATA_INSTALL_LOG=${DATA_DIR}install.log

# module init
MOD_DIR=""
MOD_NAME=""
MOD_INSTALL_SCRIPT=""
MOD_PACKAGE_DIR=""
MOD_CONF_DIR=""

# component init
COM_DIR=""
COM_NAME=""
COM_SOURCE_FILE=""
COM_INSTALL_DIR=""
COM_INSTALL_SCRIPT=""
COM_PACKAGE_DIR=""
COM_CONF_DIR=""
COM_DATA_CONF_DIR=""
COM_DATA_DB_DIR=""
COM_DATA_SCRIPT_DIR=""
COM_DATA_LOG_DIR=""


# define function
outlog(){
	local date=`date +"%Y-%m-%d %H:%M:%S"`
	echo "${date} ${1}"|tee -a $DATA_INSTALL_LOG
}

error() {
	echo -e "\033[0;31;1m Installation Failed:\033[0m\n  ${1}";
	outlog "${1}"
	tmp_clear
	exit 1;
}

user_add() {
	local g=$1
	local u=$2

	if [ "${g}" == "" ]; then
		return;
	fi

	if [ "${u}" == "" ]; then
		u="${g}";
	fi

	if [ `cat /etc/group|grep "^${g}:"|wc -l` -eq "0" ]; then
		groupadd $g
	fi
    if [ `cat /etc/passwd|grep "^${u}:"|wc -l` -eq "0" ]; then
		useradd -g $g  $u
    fi
}

createdir() {
	if [ "${1}" = "" ]; then
		return;
	fi
	for p in $@; do
		if [ -d "$_p" ]; then
			continue;
		fi
		mkdir -p -m 777 $p;
	done
}

pkg_install() {
	if [ "${SYSTEM_NAME}" == 'centos' ]; then
		yum_install "$@";
	fi
}

pkg_uninstall() {
	if [ "${SYSTEM_NAME}" == 'centos' ]; then
		yum_uninstall "$@";
	fi
}

killport() {
	if [ ! "${1}" ]; then
		return;
	fi
	local pn= `netstat -anp|grep ":$1\s"|awk '{print $7}'|awk -F'/' '{print $2}'|awk -F':' '{print $1}'`
	if [ "${pn}" != "" ]; then
		killall -9 $pn
	fi
}

pkg_conf_get() {
	if [ "${PKG_SOURCE_CONF}" == "" ];then
		if [[ "${CURRENT_IS_BUILD}" == "1" ]] && [[ -f "${GIT_DIR}/pkg.cnf" ]];then
			PKG_SOURCE_CONF=`cat "${GIT_DIR}/pkg.cnf"|tr "\n" " "`
		else
			if [ `curl -s -i ${SOURCE_URL}"pkg.cnf"|grep -e 'HTTP/1.1 200 OK' -e 'HTTP/2 200' |wc -l` == '0' ];then
				error "Curl connect timeout, ${SOURCE_URL}"
			fi
			PKG_SOURCE_CONF=`curl -s ${SOURCE_URL}"pkg.cnf"|tr "\n" " "`
		fi
		
	fi
	echo -e ${PKG_SOURCE_CONF[*]}|tr " " "\n"
}

com_tmp_init() {
	if [ "${TMP_COM_DIR}" != "" ]; then
		if [ -e $TMP_COM_DIR ]; then
			rm -rf  $TMP_COM_DIR"*"
		else
			createdir $TMP_COM_DIR
        fi
	fi
}

com_source_get() {
	local cname=$1
	local cdir=$2
	local com_name="linux-component-"${cname}
	local pkg_file=${PKG_COMPONENT_DIR}${com_name}".zip"	
	local pkg_tmp_dir=""
	local pkg_url=""
	local pkg_cnf=""
	local fzip=""
	local pkg_list=""
	if [ ! -f "${pkg_file}" ]; then
		if [ `pkg_conf_get|grep $com_name|wc -l` == "0" ]; 
		then
			return
		fi
		
		pkg_tmp_dir=$TMP_PKG_DIR$com_name"/"
		if [ "$pkg_tmp_dir" != "" ] && [ -e "$pkg_tmp_dir" ]; 
		then
			rm -rf $pkg_tmp_dir
		else
			mkdir -m 777 -p $pkg_tmp_dir
		fi
		
		cd $pkg_tmp_dir
		pkg_cnf="${GIT_DIR}/pkg/${com_name}.cnf"
		if [[ "${CURRENT_IS_BUILD}" == "1" ]] && [[ -f "${pkg_cnf}" ]];then
			pkg_list=(`cat $pkg_cnf|tr "\n" " "`);
			for fname in "${pkg_list[@]}"; do
				fzip=${GIT_DIR}/pkg/$fname
				if [ -f $fzip ];then
					\cp -f $fzip $fname;
				fi
			done
		else
			pkg_url=$SOURCE_URL"pkg/"$com_name".cnf"
			pkg_list=(`curl -s $pkg_url|tr "\n" " "`)
			echo "" > "${com_name}.cnf"
			for fname in "${pkg_list[@]}"; do
				furl=$SOURCE_URL"pkg/"$fname
				echo $furl >> "${com_name}.cnf"
			done
			wget -i "${com_name}.cnf"
		fi
		zip "${com_name}.zip" -s=0 --out $pkg_file
	fi
	unzip $pkg_file -d $cdir
}

com_install_init() {
	if [ "$1" = "" ]; then
		return;
	fi
	
	COM_NAME="$1"
	COM_DIR="${SOURCE_COMPONENT_DIR}${com}/"
	COM_PACKAGE_DIR="${COM_DIR}package/"
	COM_SOURCE_FILE=""
	COM_CONF_DIR="${COM_DIR}conf/"
	COM_INSTALL_SCRIPT="${COM_DIR}install_${SYSTEM_VERSION}.sh"
	COM_INSTALL_DEFAULT_SCRIPT="${COM_DIR}install.sh"
	COM_INSTALL_DIR="${INSTALL_DIR}${com}/"
	COM_DATA_CONF_DIR="${DATA_CONF_DIR}${com}/"
	COM_DATA_DB_DIR="${DATA_DB_DIR}${com}/"
	COM_DATA_SCRIPT_DIR="${DATA_SCRIPT_DIR}${com}/"
	COM_DATA_LOG_DIR="${DATA_LOG_DIR}${com}/"
	COM_DATA_CACHE_DIR="${DATA_CACHE_DIR}$com/"
}

com_install_clear() {
	COM_NAME=""
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
}

com_install() {
	if [ "${1}" = "" ]; then
		return;
	fi
	
	local com
	for com in $1; do
		com_install_init "$com"
		if [ ! -d "${COM_DIR}" ]; then
			com_source_get "$COM_NAME" "$SOURCE_COMPONENT_DIR"
			if [ ! -d "${COM_DIR}" ]; then
				error "Component:${com} failed to download!"
			fi
		fi
				
		if [ ! -f "${COM_INSTALL_SCRIPT}" ] && [ ! -f "${COM_INSTALL_DEFAULT_SCRIPT}" ]; then
			error "Failed to install component ${com}: ${COM_INSTALL_SCRIPT} && ${COM_INSTALL_DEFAULT_SCRIPT} is not exists!"
		fi

		echo "component ${com} installation started!";
		cd $CURRENT_DIR
		if [ -f "${COM_INSTALL_SCRIPT}" ]; then
			echo $COM_INSTALL_SCRIPTß
			source $COM_INSTALL_SCRIPT
		elif [ -f $COM_INSTALL_DEFAULT_SCRIPT ]; then
			echo $COM_INSTALL_DEFAULT_SCRIPT
			source $COM_INSTALL_DEFAULT_SCRIPT
		fi
        sleep 2
        echo "component：${com} installation stoped"
		com_install_clear
	done

}

com_untar() {
	tar zxvf $1 -C $TMP_COM_DIR > /dev/null
}

com_untarxz() {
	tar xvf $1 -C $TMP_COM_DIR > /dev/null
}

com_unzip() {
	unzip  -u $1  -d $TMP_COM_DIR > /dev/null
}

com_unbz2(){
	tar jxvf $1 -C $TMP_COM_DIR > /dev/null
}

com_init() {
	local is_cover=""
	COM_SOURCE_FILE="${COM_PACKAGE_DIR}${1}"
	
	if [ ! -f "${COM_SOURCE_FILE}" ]; then
		error "Failed to install component ${COM_NAME}: ${COM_SOURCE_FILE} is not exists!"
	fi
	    
	if [ -d "${COM_INSTALL_DIR}" ]; then
		echo -n "component ${COM_NAME} has been installed. Do you want to overwrite the installation(y/n):"
		read is_cover
		if [ "${is_cover}" != "y" ] && [ "${is_cover}" != "Y" ]; then
			error "Failed to install component ${COM_NAME}: installation terminated!"
		fi
	fi
}

com_pkg_check() {
	for pkg in "$@"; do
		if [ ! -f "${pkg}" ]; then
        	error "Failed to install component {COM_NAME}: ${pkg} is not exists!"
		fi
	done
}

com_file_replace() {
	local s=$1
	local t=$2
	local path=$3
	t=${t//\//\\\/}
	sed -i "s/${s}/${t}/g" $path
}

com_replace() {
	for path in "$@"; do
		if [ ! -f "$path" ]; then
			error "Failed to install component ${COM_NAME},${path} is not exists!"
		fi
		com_file_replace '{COM_DATA_CONF_DIR}' "${COM_DATA_CONF_DIR}" $path
		com_file_replace '{COM_DATA_DB_DIR}' "${COM_DATA_DB_DIR}" $path
		com_file_replace '{COM_INSTALL_DIR}' "${COM_INSTALL_DIR}" $path
		com_file_replace '{COM_DATA_CACHE_DIR}' "${COM_DATA_CACHE_DIR}" $path
		com_file_replace '{COM_DATA_SCRIPT_DIR}' "${COM_DATA_SCRIPT_DIR}" $path
		com_file_replace '{COM_DATA_LOG_DIR}' "${COM_DATA_LOG_DIR}" $path
		com_file_replace '{CPU_NUM}' "${CPU_NUM}" $path
	done
}

com_install_test() {
	if [ ! -e "${COM_INSTALL_DIR}" ]; then
		error "Failed to install component ${COM_NAME}: the installation path ${COM_INSTALL_DIR} is not exists!"
	fi

	for path in $@; do
		if [ ! -e "$path" ];then
			error "Failed to install component ${COM_NAME}: the installation path ${path} is not exists!"
		fi
	done
}

require(){
	local com_current_name="$COM_NAME"
	com_install "$*";
	if [ "${com_current_name}" != "" ]; then
		com_install_init "${com_current_name}"
	fi
}

mod_tmp_init() {
	if [ "${TMP_MOD_DIR}" != "" ];then
		if [ -e "${TMP_MOD_DIR}" ];then
			rm -rf  "${TMP_MOD_DIR}*"
		else
			createdir "${TMP_MOD_DIR}"
		fi
	fi
}

mod_source_get() {
    local mname=$1
    local mdir=$2
    local mod_name="linux-module-"${mname}
    
    local pkg_file=${PKG_COMPONENT_DIR}${mod_name}".zip"    
    local pkg_tmp_dir=""
    local pkg_url=""
    local pkg_list=""
    if [ ! -f "${pkg_file}" ]; then
        
        if [ `pkg_conf_get|grep $mod_name|wc -l` == "0" ]; 
        then
            return
        fi

        pkg_tmp_dir=$TMP_PKG_DIR$mod_name"/"
        if [ "$pkg_tmp_dir" != "" ] && [ -e "$pkg_tmp_dir" ]; 
        then
            rm -rf $pkg_tmp_dir
        else
            mkdir -m 777 -p $pkg_tmp_dir
        fi
        
        cd $pkg_tmp_dir
        pkg_url=$SOURCE_URL"pkg/"$mod_name".cnf"
        pkg_list=(`curl -s $pkg_url|tr "\n" " "`)
        
        echo "" > "${mod_name}.cnf"
        for fname in "${pkg_list[@]}"; do
            furl=$SOURCE_URL"pkg/"$fname
            echo $furl >> "${mod_name}.cnf"
        done
        
        wget -i "${mod_name}.cnf"
        zip "${mod_name}.zip" -s=0 --out $pkg_file
    fi
    unzip $pkg_file -d $mdir
}

mod_install_init() {
    if [ "$1" = "" ]; then
        return;
    fi
    MOD_DIR="${SOURCE_MODULE_DIR}${1}/"
    MOD_NAME=$1
    MOD_PACKAGE_DIR="${MOD_DIR}package/"
    MOD_CONF_DIR="${MOD_DIR}conf/"
    MOD_INSTALL_SCRIPT="${SOURCE_MODULE_DIR}${mod}/install.sh"
}

mod_install_clear() {
    MOD_DIR=""
    MOD_NAME=""
    MOD_PACKAGE_DIR=""
    MOD_CONF_DIR=""
    MOD_INSTALL_SCRIPT=""
}

mod_install() {
	if [ "${1}" = "" ]; then
		return
	fi
	
	local mod
	for mod in $1; do
		mod_install_init "${mod}"
		if [ ! -d "${MOD_DIR}" ]; then
		    mod_source_get "$MOD_NAME" "$SOURCE_MODULE_DIR"
            if [ ! -d "${MOD_DIR}" ]; then
                error "Module:${mod} failed to download!"
            fi
		fi

		if [ ! -f "${MOD_INSTALL_SCRIPT}" ]; then
			error "Failed to install module ${mod}: ${MOD_INSTALL_SCRIPT} is not exists!"
		fi
                
		echo "Module ${mod} installation started!"
		cd $CURRENT_DIR
		source $MOD_INSTALL_SCRIPT
		echo "Module ${mod} installation successfully!"
		sleep 2
        mod_install_clear
   done
}


mod_untar() {
	tar zxvf $1 -C $TMP_MOD_DIR >/dev/null
}

mod_unzip() {
	unzip -f $1 -d $TMP_MOD_DIR >/dev/null
}

mod_unbz2() {
	tar jxvf $1 -C $TMP_MOD_DIR >/dev/null
}


hasoption(){
	inarray "${1}" "${CURRENT_OPTIONS[*]}"
}

tmp_clear(){
    if [ "${TMP_DIR}" != "" ] && [ -d "${TMP_DIR}" ]; then
        rm -rf $TMP_DIR
    fi
}

CPU_NUM=`cat /proc/cpuinfo|grep -e "model name" -e "processor"|wc -l`
if [ -n $(echo $MAKE_MAX_CPU_NAME| sed -n "/^[0-9]\+$/p") ] && [ $CPU_NUM -gt $MAKE_MAX_CPU_NAME ]; then
	CPU_NUM=$MAKE_MAX_CPU_NAME
fi

if [ $CPU_NUM -lt 1 ]; then
	CPU_NUM=1
fi

createdir $DATA_DIR $DATA_BAK_DIR
createdir $PKG_DIR $PKG_COMPONENT_DIR $PKG_MODULE_DIR
createdir $SOURCE_DIR $SOURCE_COMPONENT_DIR $SOURCE_MODULE_DIR
createdir $DATA_BAK_DIR $DATA_WEB_DIR $DATA_DB_DIR $DATA_SCRIPT_DIR $DATA_CONF_DIR

if [ -f /etc/centos-release ]; then
	SYSTEM_NAME="centos"
	SYSTEM_VERSION="centos.7x"
fi

INSTALL_SYSTEM_SCRIPT="${CURRENT_DIR}/init_${SYSTEM_NAME}.sh"
if [ -f $INSTALL_SYSTEM_SCRIPT ]; then
	source $INSTALL_SYSTEM_SCRIPT
fi

if [ ${#CURRENT_COMPONENTS} == 0 ] && [  ${#CURRENT_MODULES} == 0 ];then
	CURRENT_MODULES[0]="lnmp"
fi

com_tmp_init
com_install "${CURRENT_COMPONENTS[*]}"

mod_tmp_init
mod_install "${CURRENT_MODULES[*]}"

if [ "${CURRENT_IS_NO_CLEAR}" == '0' ]; then
	tmp_clear
fi
