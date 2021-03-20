#!/bin/bash

read -r -p "Please input IP to check and unban: " ip
cmd_f2ban=/usr/bin/fail2ban-client
cat /dev/null > /tmp/jail_service_block.status

for jail_service in `$cmd_f2ban status | grep "Jail list:" | awk -F":" '{print $2}' | sed 's/[,]/ /g;s/[[:blank:]]/\n/g'`
do
  if [[ ! -z $($cmd_f2ban status $jail_service | grep $ip) ]]; then
    echo $jail_service >> /tmp/jail_service_block.status
  fi
done
if [ -s /tmp/jail_service_block.status ]; then
  jail_service=`cat /tmp/jail_service_block.status`
  $cmd_f2ban set $jail_service unbanip $ip > /dev/null
  echo "===================================================="
  echo "IP $ip blocked by $jail_service --> has been unbaned"
  echo "=====================Reason========================="
  grep $ip /var/log/dovecot/imap.log | grep "failed" | tail -5
  grep $ip /var/log/dovecot/pop3.log | grep "failed" | tail -5
  grep $ip /var/log/maillog | tail -5
  echo "===================================================="
else
  echo "IP $ip not blocked"
fi
