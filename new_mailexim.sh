#!/bin/bash

apt-get install sshpass

###keygen
rm -rf /root/.ssh
ssh-keygen -f ~/.ssh/id_rsa -q -P ""
sshpass -p '398#e5cUy9$' ssh-copy-id  -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub bkmail@192.168.89.114

###down cron 
wget -O /root/check_queue.sh http://192.168.93.202/script/check_queue.sh
wget -O /root/rsync_local.sh http://192.168.93.202/script/rsync_local.sh
wget -O /root/rsync_remote.sh http://192.168.93.202/script/rsync_remote.sh

###crontab
crontab -r

cat > /var/spool/cron/crontabs/root <<EOF
# m h  dom mon dow   command
0 1 * * * /root/monitor_diskspace.sh >/dev/null
0 * * * * rdate -s rdate.cpanel.net
0 */6 * * * chown -R bkmail.bkmail /backup/zip
#0 19 * * * sh /root/rsync_local_ifmount.sh
#0 19 * * * rsync -az --delete /opt/kerio/mailserver /backup/backup_rsync
#0 2 * * * rsync -auvz --delete -e "ssh -l ssh-user" /backup/backup_rsync bkmail@192.168.89.114:/home2/backup_kerio/93.148
0 22 * * 6 sh /root/rsync_remote.sh
0 1 * * 3 sh /root/rsync_local.sh
*/30 * * * * sh /root/check_queue.sh
* * * * * sh /usr/lib/nagios/plugins/kerio_mailqueue -w 300 -c 400
EOF

###monitor
sed -i s/'TCP_OUT* *=.* *'/'TCP_OUT = "20,21,22,25,53,80,110,113,443,587,993,995,123,37"'/ /etc/csf/csf.conf
echo "tcp|in|d=5666|s=192.168.95.206" >> /etc/csf/csf.allow && csf -r
apt-get update; apt-get install nagios-nrpe-server nagios-plugins -y
wget http://112.213.89.97/89.7/kerio_mailqueue -O /usr/lib/nagios/plugins/kerio_mailqueue
chmod +x /usr/lib/nagios/plugins/kerio_mailqueue
sed -i 's/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,192.168.95.206/g' /etc/nagios/nrpe.cfg

/etc/init.d/nagios-nrpe-server restart
update-rc.d nagios-nrpe-server defaults
