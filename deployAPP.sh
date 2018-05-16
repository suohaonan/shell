#!/bin/bash

# function auto deploy tomcat
# author:CG deployAPP
# version 0.1

# tomcat启动程序(这里注意tomcat实际安装的路径)
rootPath=`pwd`
backupPath=${rootPath}/backup/
defaulttomcatPath=${rootPath}/apache-tomcat-7.0.59/
tomcatPath=$3
if [ ! $tomcatPath ];then
        tomcatPath=${defaulttomcatPath}
else
	tomcatPath=${rootPath}/${tomcatPath}/
fi


# 项目名称(根据实际情况进行配置)
warDir=/home/jyapp/$1
warName=$1
depAppTarName=$2
deleteJAR=$4
fileDate=$(date "+%m%d%H%M%S")
fileName=$1"_bak"${fileDate}
appTar=/home/jyapp/$2
#获取tomcat进程ID
tomcatID=$(ps -ef | grep ${tomcatPath} | grep -v 'grep' | awk  '{print $2}')

startTomcat=${tomcatPath}/bin/startup.sh
workSpace=$(pwd)

#主函数
function monitor()
{
  echo "[info]开始监控tomcat...[$(date +'%F %H:%M:%S')]"
  
  if [ ! $depAppTarName ]; then
	echo "1 或 2 参数为null，请补充参数"
	exit 1
  fi

  if [ "$tomcatID" ];then
        echo "[info]当前tomcat进程ID为:$tomcatID"
        kill -9 $tomcatID
  fi
  backup
  removeJAR
  upload
  startTomcat
}  
#启动tomcat
function startTomcat(){
     cd $workSpace
     if [ -d "$warDir" ]; then
	 source /etc/profile
         $startTomcat
         #tail -f ${tomcatPath}/logs/catalina.out
	 echo "===start ok======="
     else
         echo "startTomcat 没有app: $warDir"
     fi
}
#上传文件
function upload(){
    cd $workSpace
    if [ -d "$warDir" ]; then
        tar -zxvf $depAppTarName  -C $warDir ;
    else
	echo "upload error 不存在 $warDir " 
    fi
    cd $workSpace
}
#清除tomcat的项目缓存
function removeJAR(){
   cd $workSpace
   echo "开始清理tomcat的项目缓存"
   if [ -d "$tomcatPath" ]; then
     rm -rf $tomcatPath/work/* 
     rm -rf $tomcatPath/temp/*
   else  
     echo "remove JAR不存在 $tomcatPath"        
   fi
   #删除 对应的jar包
   if [ $deleteJAR ]; then  
        #rm -f "$warDir/WEB-INF/lib"
	echo "delete jar ok $deleteJAR"
    else  
        echo "no removeJAR jar $warDir"         
   fi  
   echo "清理完毕"  
}  
#备份原来的项目  
function backup(){
    cd $workSpace  
    echo "开始备份...."
    if [ -d "$warDir" ]; then     
        cd $workSpace
        tar -zcf ${fileName}.tar.gz $warName
		mv ${fileName}.tar.gz ${backupPath}
        cd $workSpace
       	echo "备份完毕..."
    else
        echo "backup error 不存在$warDir"
    fi
}  

monitor
