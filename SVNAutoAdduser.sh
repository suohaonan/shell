#SVN开权限脚本
#使用时需要传入两个参数RepoName（SVN库信息）、NewUserName（用户信息）

#数据库配置信息
host=
db_user=
db_pwd=

#获取项目名称、项目经理、SVN库名、SVN地址信息
pro_name=$(echo $RepoName|cut -d , -f 1)
pro_manager=$(echo $RepoName|cut -d , -f 2)
svn_name=$(echo $RepoName|cut -d , -f 3)
svn_addr=

#查询SVN库是否存在，0或1正常，大于1时需要检查数据库
repo_exist=$(ssh -o StrictHostKeyChecking=no -n  "mysql -h$host -u$db_user -p$db_pwd -e \"SELECT count(*) FROM svn_data.Program WHERE pro_name='$pro_name';\"")
repo_result=$(echo $repo_exist|awk '{print $2}')
echo $repo_result

#SVN哭不存在，新建库
if [ "$repo_result" = "0" ]; then
    echo "svnrepo not exist!!!!!!!!!"
    cd /app/svnData
    #创建库
    svnadmin create $svn_name
    #替换标准authz配置文件
    cp -rp /app/svnData/authz /app/svnData/$svn_name/conf
    #修改svnserve.conf配置文件
    cd /app/svnData/$svn_name/conf
    sed -n '/# anon-access = read/p' svnserve.conf | sed 's/# anon-access = read/anon-access = none/g' svnserve.conf > svnserve_new.conf
    rm svnserve.conf
    mv svnserve_new.conf svnserve.conf
    sed -n '/# auth-access = write/p' svnserve.conf | sed 's/# auth-access = write/auth-access = write/g' svnserve.conf > svnserve_new.conf
    rm svnserve.conf
    mv svnserve_new.conf svnserve.conf
    sed -i -r -e '27s/^# (.*)/\1/g' -e '20s/^# (.*)/\1/g' -e '12,13s/^# (.*)/\1/g' -e "32s/# (.*=)(.*)/\1 \/app\/svnData\/$svn_name/" svnserve.conf
    #导入标准库结构
    cd /app/svnData
    svnadmin load $svn_name < /app/Standard_Library
    #将新库信息存入数据库
    ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"INSERT INTO svn_data.Program (pro_name,pro_manager,svn_name,svn_addr) VALUES ('$pro_name','$pro_manager','$svn_name','$svn_addr')\""
    

    cd /app/svnData/$svn_name/conf
    #添加用户，支持一次添加多个用户
    for user in $NewUserName
    do
        #将用户信息添加到 passwd配置文件中
        echo "# $user ">>passwd
        #获取用户名字、用户名、权限分组
        user_name=$(echo $user|cut -d , -f 1)
        username=$(echo $user|cut -d , -f 2)
        group=$(echo $user|cut -d , -f 3)
        #查询用户是否存在，0或1正常，大于1时需要检查数据库
        user_exist=$(ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"SELECT count(*) FROM svn_data.User_info WHERE user_name='$user_name';\"")
        user_result=$(echo $user_exist|awk '{print $2}')
        echo $user_result
        #用户不存在时，将用户存入数据库
        if [ "$user_result" = "0" ]; then
             echo "用户不存在，已新建该用户并添加至库内"
             userpasswd=$(openssl rand -base64 6)
             echo $user_name
             echo $username
             echo $userpasswd
             mysql -h$host -u$db_user -p$db_pwd -e "INSERT INTO svn_data.User_info (user_name,username,passwd) VALUES ('$user_name','$username','$userpasswd')"

        else
             #用户已存在时，获取用户现有的密码
             echo "用户已存在，已添加至对应库内"
             userpasswd_tmp=$(ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"SELECT passwd FROM svn_data.User_info WHERE username='$username';\"")
             userpasswd=$(echo $userpasswd_tmp|awk '{print $2}')
             echo $userpasswd
        fi
        echo $(pwd)
        #将用户的账号信息、权限分组写入配置文件中
        sed "$ a\
        $username = $userpasswd
        " passwd >>passwd_new
        mv passwd passwd_bak
        mv passwd_new passwd
        sed "s/"$group="/"$group=$username,"/g" authz >>authz_new
        mv authz authz_bak
        mv authz_new authz      
        echo "------------------------------------------------------"
        ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"INSERT INTO svn_data.user_svn(pro_id,user_id) VALUES((SELECT pro_id FROM svn_data.Program WHERE pro_name='$pro_name'),(SELECT user_id FROM svn_data.User_info WHERE user_name='$user_name'));\""
    done
else
    echo "svnrepo exist!!!!!!!!!"
    cd /app/svnData/$svn_name/conf
    for user in $NewUserName
    do
        echo "# $user ">>passwd
        user_name=$(echo $user|cut -d , -f 1)
        username=$(echo $user|cut -d , -f 2)
        group=$(echo $user|cut -d , -f 3)
        user_exist=$(ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"SELECT count(*) FROM svn_data.User_info WHERE user_name='$user_name';\"")
        user_result=$(echo $user_exist|awk '{print $2}')
        echo $user_result
        if [ "$user_result" = "0" ]; then
             echo "用户不存在，已新建该用户并添加至库内"
             userpasswd=$(openssl rand -base64 6)
             echo $user_name
             echo $username
             echo $userpasswd
             ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"INSERT INTO svn_data.User_info (user_name,username,passwd) VALUES ('$user_name','$username','$userpasswd');\""

        else
             echo "用户已存在，已添加至对应库内"
             userpasswd_tmp=$(ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"SELECT passwd FROM svn_data.User_info WHERE username='$username';\"")
             userpasswd=$(echo $userpasswd_tmp|awk '{print $2}')
             echo $userpasswd
        fi
        echo $(pwd)
        sed "$ a\
        $username = $userpasswd
        " passwd >>passwd_new
        mv passwd passwd_bak
        mv passwd_new passwd
        sed "s/"$group="/"$group=$username,"/g" authz >>authz_new
        mv authz authz_bak
        mv authz_new authz      
        echo "------------------------------------------------------"
        ssh -o StrictHostKeyChecking=no -n 192.168.1.1 "mysql -h$host -u$db_user -p$db_pwd -e \"INSERT INTO svn_data.user_svn(pro_id,user_id) VALUES((SELECT pro_id FROM svn_data.Program WHERE pro_name='$pro_name'),(SELECT user_id FROM svn_data.User_info WHERE user_name='$user_name'));\""
    done
fi
