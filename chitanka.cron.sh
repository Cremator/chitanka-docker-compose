#!/usr/bin/env bash
set -e
if [[ $(apk list -I|grep -c -E '^git-\d|^less-\d|^openssh-\d|^patch-\d|^rsync-\d|^curl-\d|^wget-\d') != 7 ]]; then
    apk fix&&\
    apk --no-cache --update add git less openssh patch rsync curl wget
fi
if [[ ! -f /usr/local/bin/docker-compose ]]; then
    wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -q -O /usr/local/bin/docker-compose&&\
    chmod a+x /usr/local/bin/docker-compose
fi
if [[ ! -f /opt/crontab/chitanka_git/composer.json ]]; then
    git clone --depth 1 $CRON_CHITANKA_GIT /opt/crontab/chitanka_git
fi
cd /opt/crontab/chitanka_git && git pull && cd -
rsync -avvr --delete --exclude /web/content /opt/crontab/chitanka_git/ /opt/crontab/chitanka_content/ && rm -rf /opt/crontab/chitanka_content/var/cache/*
chmod -R a+w /opt/crontab/chitanka_content/var/cache /opt/crontab/chitanka_content/var/log /opt/crontab/chitanka_content/var/spool /opt/crontab/chitanka_content/web/cache 
cp /opt/crontab/parameters.yml /opt/crontab/chitanka_content/app/config/parameters.yml
wget http://download.chitanka.info/chitanka.sql.gz -q -O /opt/crontab/mysql_db_init/chitanka.sql.gz
rsync -avvz --delete $CRON_CHITANKA_CONTENT /opt/crontab/chitanka_content/web/content/
/usr/local/bin/docker-compose -f /opt/crontab/docker-compose.yml rm -f -s -v mariadb
/usr/local/bin/docker-compose -f /opt/crontab/docker-compose.yml create mariadb
/usr/local/bin/docker-compose -f /opt/crontab/docker-compose.yml restart mariadb php-fpm nginx