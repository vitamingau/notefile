#!/bin/bash

RED="\033[1;31m"
GREEN="\033[1;32m"
NOCOLOR="\033[0m"
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

file_default=/etc/nginx/sites-enabled/mail.default-domain
file_postfix=/etc/postfix/vmail_ssl.map
file_dovecot=/etc/dovecot/dovecot.conf
folder_backup_dovecot=/etc/dovecot/backup_file_config
folder_backup_postfix=/etc/postfix/backup_file_config
file_get_ip=/etc/postfix/sdd_transport.pcre

read -r -p "Please input Domain need setup SSL: " domain


##Import to file config dovecot
func_import_dovecot(){
if grep -ql $1 $file_dovecot; then
echo -e "${RED}Domain ${NOCOLOR}${BOLD}$1${NORMAL} ${RED}exist contain file dovecot config${NOCOLOR}"
exit;
else
cp $file_dovecot $folder_backup_dovecot/dovecot.conf-`date +%H":"%M":"%S_%F`
line_number=`grep -n "# Fix 'The Logjam Attack'" $file_dovecot | awk -F":" '{print $1}'`
ex $file_dovecot <<eof
$line_number insert
############SNI mail.$1 ###############
local_name mail.$1 {
  ssl_cert = </etc/letsencrypt/live/mail.$1/fullchain.pem
  ssl_key = </etc/letsencrypt/live/mail.$1/privkey.pem
}
#####################################

.
xit
eof
fi
}

##Import to file config postfix
func_import_postfix(){
if grep -ql $1 $file_postfix; then
echo -e "${RED}Domain ${NOCOLOR}${BOLD}$1${NORMAL} ${RED}exist contain file postfix config${NOCOLOR}"
exit;
else
cp $file_postfix $folder_backup_postfix/vmail_ssl.map-`date +%H":"%M":"%S_%F`
echo "mail.$1 /etc/letsencrypt/live/mail.$1/privkey.pem,/etc/letsencrypt/live/mail.$1/fullchain.pem" >> $file_postfix
fi
}

mysql -u root vmail -e  "SELECT * FROM domain WHERE domain REGEXP '(^|[[:space:]])$domain([[:space:]]|$)';" | \
if grep -ql "$domain"; then ###Check domain exist in database
  ip_domain=`cat $file_get_ip | grep $domain | awk -F" " '{print $2}' | awk -F"-" '{print $1}'`
  if [ -z $ip_domain ]; then
    echo -e "${RED}Domain${NOCOLOR} ${BOLD}$domain${NORMAL} ${RED}doesn't exist on file: $file_get_ip${NOCOLOR}"
    exit;
  fi
  file_domain=/etc/nginx/sites-enabled/mail.$domain.conf
  if [ ! -d /etc/letsencrypt/live/mail.$domain ]; then
    mkdir /etc/letsencrypt/live/mail.$domain
  fi
  if [ ! -f /etc/letsencrypt/live/mail.$domain/fullchain.pem ] && \
    [ ! -f /etc/letsencrypt/live/mail.$domain/privkey.pem ]; then ###Check file Cert SSL + Private key exist
    echo "======================================"
    echo -e "Please input ${RED}Certificate + CARoot SSL's${NOCOLOR} for domain ${BOLD}$domain${NORMAL} into file ${GREEN}/etc/letsencrypt/live/mail.$domain/fullchain.pem${NOCOLOR}\nPlease input ${RED}Private key's${NOCOLOR} for domain ${BOLD}$domain${NORMAL} into file ${GREEN}/etc/letsencrypt/live/mail.$domain/privkey.pem${NOCOLOR}"
    exit;
  else
    if [ ! -f $file_domain ]; then
      cp $file_default $file_domain
      echo "======================================"
      /usr/bin/replace "DOMAIN" "$domain" -- $file_domain
      /usr/bin/replace "IP_MAIL" "$ip_domain.maychuemail.com" -- $file_domain
      nginx -t 2>&1 | tee /tmp/nginx.status | \
      if grep -ql "successful"; then
	echo "======================================"
        echo "Reload NGINX service to apply new config for domain ${BOLD}$domain${NORMAL} ...."
        systemctl reload nginx
	echo "======================================"
	echo "Import config for domain ${BOLD}$domain${NORMAL} to Postfix and Dovecot ...."
        func_import_dovecot $domain
        func_import_postfix $domain
	echo "======================================"
        echo "Postmap + Restart Postfix service and Dovecot service ...."
        if [[ -z $(postmap -F hash:/etc/postfix/vmail_ssl.map 2>&1) ]]; then
          if [[ -z $(systemctl restart postfix 2>&1) ]]; then
            echo -e "${GREEN}Postfix restart sucessfully${NOCOLOR}"
            echo "======================================"
          else
            echo -e "${RED}Postfix restart failed, please check again${NOCOLOR}"
            exit;
          fi
          if [[ -z $(systemctl restart dovecot 2>&1) ]]; then
            echo -e "${GREEN}Dovecot restart sucessfully${NOCOLOR}"
            echo "======================================"
          else
            echo -e "${RED}Dovecot restart failed, please check again${NOCOLOR}"
            exit;
          fi
        else
          echo -e "${RED}Postmap config not OK, please check again${NOCOLOR}"
        fi
      else
        echo -e "${RED}Nginx service not OK, please check again${NOCOLOR}"
      fi
    else
      echo -e "${RED}File config Virtualhost' domain ${BOLD}$domain${NORMAL} exist, please check again${NOCOLOR}"
    fi
  fi
else
  echo -e "${RED}Domain${NOCOLOR} ${BOLD}$domain${NORMAL} ${RED}doesn't exist${NOCOLOR}"
fi
