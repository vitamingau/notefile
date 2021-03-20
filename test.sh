#/bin/bash

read -r -p "Nhap user : " ten_user
tendomain=`cat /etc/trueuserdomains | grep $ten_user | awk -F":" '{print $1}'`
duongdan=`cat /var/cpanel/userdata/$ten_user/$tendomain | grep documentroot | awk -F":" '{print $2}'`
echo $duongdan
