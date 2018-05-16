#!/bin/bash

# function auto deploy tomcat
# author:suohaonan deployAPP
# version 0.2

# tomcat启动程序(这里注意tomcat实际安装的路径)


export LANG="en_US.UTF-8"
export JAVA_HOME=/app/jdk7
if [ $# != 2 ];then
    echo -e "\033[31m Usage:   sh $0 [Tomcat路径] [配置文件路径] [war包路径] \033[0m"
    echo -e "\033[31m Warring: 路径目录后面不要带'/',并且是绝对路径 \033[0m"
    exit 1
else
    Tomcatpath=$1
    Warpath=$2
    Date=$(date +%Y%m%d%H%M)
fi
echo -e "\033[32m -------------------->[杀死进程] \033[0m"
######## kill pid
Pid=$(ps -ef |grep $Tomcatpath/conf|grep -v grep |awk '{print $2}')
if [ ! -n "$Pid" ];then
    echo "----------------------->$Tomcatpath   is not start"
else
    kill -9 $Pid
fi

echo -e "\033[32m --------------------->[开始备份] \033[0m"
########Backup webapps or Unzip or Replace configuration file
if [ -d "$Tomcatpath/bak" ];then
    echo "备份路径存在"
else
    mkdir $Tomcatpath/bak 
fi

WebappsPath=`grep  'docBase' $Tomcatpath/conf/server.xml|grep -v '<!--'|awk -F '"' '{print $6}'`
PackageName=`grep  'docBase' conf/server.xml|grep -v '<!--'|awk -F '"' '{print $6}'|awk -F '[/]+' '{print $NF}'`



if [ ! -n "$WebappsPath" ];then
    mv $Tomcatpath/webapps/ROOT $Tomcatpath/bak/ROOT_$Date
    if [ -f $Warpath ];then
       unzip -q $Warpath -d $Tomcatpath/webapps/ROOT && rm -f $Warpath
    else
       echo "-------------------------->$Warpath   is  not exit......................"
       exit 2
    fi
    echo -e "\033[32m --------------------->[备份路径$Tomcatpath/bak/ROOT_$Date] \033[0m"
    #echo -e "\033[32m --------------------->[开始替换配置文件] \033[0m"
    #cp $Confpath/* $Tomcatpath/webapps/ROOT/WEB-INF/classes
else
    mv $WebappsPath $Tomcatpath/bak/`$PackageName`_$Date
    if [ -f $Warpath ];then
       unzip -q $Warpath -d $WebappsPath && rm -f $Warpath
    fi
    echo -e "\033[32m --------------------->[备份路径$Tomcatpath/bak/`$PackageName`_$Date] \033[0m"
    #echo -e "\033[32m --------------------->[开始替换配置文件] \033[0m"
    #cp $Confpath/* $WebappsPath/WEB-INF/classes

fi

echo -e "\033[32m --------------------->[开始清理缓存] \033[0m"
########Clear cache
rm -rf $Tomcatpath/work/*;
rm -rf $Tomcatpath/temp/*;
#rm -rf $Tomcatpath/log/*;
#rm -rf $Tomcatpath/bak/*;
########satrt

echo -e "\033[32m --------------------->[开始启动服务] \033[0m"
sleep 2
sh $Tomcatpath/bin/startup.sh >/dev/null 2>&1
if [ $? = 0 ];then
    tail -f $Tomcatpath/logs/catalina.out 
else
    echo -e "----------------->this \033[31m $Tomcatpath \033[0m update \033[31m error \033[0m"
fi
