#!/bin/bash
Time=`date "+%Y-%m-%d %H:%M:%S"`
LogPath=/root/Disk.log
DiskUse=`df -h|awk '{print $5}'|grep '%'|awk -F '%' '{print $1}'|grep -v Use`
chaoguozhi=90
UserEmail=


echo "----------当前时间:$Time----------" >$LogPath
#判断磁盘使用率
for line in $DiskUse;do 
    if [ $line -ge $chaoguozhi ];then
        df -h >>$LogPath
        break 
    else
        echo“"磁盘使用正常" >>$LogPath
    fi
done
####发邮件
mail -s "SVN服务器磁盘使用率！！！！！" $UserEmail < $LogPath

