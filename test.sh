#!/bin/bash

echo  "请选择安装的PHP版本(default:7.4.26):"
echo  "1: php-7.3.33"
echo  "2: php-7.4.26"
echo  "3: php-8.1.0"
read _php_version
if [ "$_php_version" == "1" ];then
	_COM_VERSION="php-7.3.33"
elif [ "$_php_version" == "2" ];then
	_COM_VERSION="php-7.4.26"
elif [ "$_php_version" == "3" ];then
	_COM_VERSION="php-8.1.0"
else
	_COM_VERSION="php-7.4.26"
fi
echo $_COM_VERSION
