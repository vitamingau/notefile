#!/bin/bash
#Shell script to monitor or watch the local backup.
#It will send an email to admin information about the local backup.
# -------------------------------------------------------------------------
# Copyright (c) 2005 nixCraft project <http://cyberciti.biz/fb/>
# This script is licensed under GNU GPL version 2.0 or above
# -------------------------------------------------------------------------
# This script is part of nixCraft shell script collection (NSSC)
# Visit http://bash.cyberciti.biz/ for more information.
# ----------------------------------------------------------------------

[ ! -d /var/log/rsync ] && mkdir /var/log/rsync

find /var/log/rsync/ -type f -mtime +30 -exec rm -rf {} \;

# Each address searated by a space
ADMIN="trangle@monitor.pavietnam.com.vn"

rsync -auvz --delete /opt/kerio/mailserver/ /backup/backup_rsync > /var/log/rsync/local-rsync-logs-`date +%d%m%Y`.log 2>&1

if [ "$?" -eq "0" ]
then
        tail -n 4 /var/log/rsync/local-rsync-logs-`date +%d%m%Y`.log |
heirloom-mailx -v -r "spammonitor@pavietnam.vn" -s "Local - Backup Completed Successfully - $(hostname)" -S smtp="mail.monitor.pavietnam.com.vn:587" -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user="spammonitor@pavietnam.vn" -S smtp-auth-password="4u657itq5kv" -S ssl-verify=ignore $ADMIN
else
        tail -n 4 /var/log/rsync/local-rsync-logs-`date +%d%m%Y`.log |
heirloom-mailx -v -r "spammonitor@pavietnam.vn" -s "Local - Backup Failed - $(hostname)" -S smtp="mail.monitor.pavietnam.com.vn:587" -S smtp-use-starttls -S smtp-auth=login -S smtp-auth-user="spammonitor@pavietnam.vn" -S smtp-auth-password="4u657itq5kv" -S ssl-verify=ignore $ADMIN
fi
