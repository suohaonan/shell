#! /bin/bash

Date=$(date +%Y%m%d%H%M)
Svndata=/home/svnData_temp
Svndata_temp=/home/svnData_temp_02
SucessEmail=
FailEmail=
SucessEmailTemplet=/home/test/SendToXitong.txt
FailEmailTemplet=/home/test/SendToCM.txt



#kill svn pid
function KillSvnPid () {
	Svn_id=$(ps -ef |grep svn |grep -v grep |awk '{print $2}')
	echo $Svn_id
	kill -9 $Svn_id
	echo svn已停服，开始压缩|mail -s "【SVN迁移】SVN已停服" $SucessEmail
}

# save some project which not transfer
# Notice:Please change the repo's name before use this scripts
function SaveRepo () {
        mv $Svndata/BUS $Svndata_temp/
        svnserve -d -r $Svndata_temp
	echo SVN服务（BUS库）已恢复|mail -s "【SVN迁移】SVN已恢复（BUS库）" $SucessEmail
}



# compress svndata and send email
function TarData () {
	cd /home
	tarname=svnData_temp_${Date}.tar.gz
	dirname=svnData_temp
	tar -czf /home/svnbackup/$tarname $dirname >/dev/null 2>&1
	if [ $? = 0 ];then
		mail -s "【SVN迁移】SVN备份已完成请上传" $SucessEmail < $SucessEmailTemplet
	else
		mail -s "【SVN迁移】SVN数据压缩报错，请检查！" $FailEmail < $FailEmailTemplet
	fi
}

#上传并解压tar包
function Upload () {
	scp -rp /home/svnbackup/$tarname 192.168.1.1:/app
	if [ $? = 0 ];then
        	echo svn上传完毕|mail -s "【SVN迁移】SVN已完成上传" $SucessEmail
	else
        	echo svn上传失败|mail -s "【SVN迁移】SVN上传报错，请检查！" $FailEmail
	fi
	ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "cd /app;tar -xf '$tarname';mv /app/'$dirname'/* /app/svnData"
	if [ $? = 0 ];then
        	echo svn解压完毕|mail -s "【SVN迁移】SVN已完成解压" $SucessEmail
	else
        	echo svn解压失败|mail -s "【SVN迁移】SVN解压报错，请检查！" $FailEmail
	fi	

}


KillSvnPid
SaveRepo
TarData
Upload
