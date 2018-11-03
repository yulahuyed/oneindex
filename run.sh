#!/bin/bash


curl -L -o oneindex.zip https://github.com/donwa/oneindex/archive/master.zip
unzip oneindex.zip
mv oneindex-master/* /home/oneindex
rm -rf oneindex.zip oneindex-master
# https://github.com/Azure-Samples/active-directory-dotnet-webapp-roleclaims/issues/19
sed -i 's/self::$client_secret/urlencode(self::$client_secret)/g' /home/oneindex/lib/onedrive.php

if [ "${DOMAIN}" ]
then
  DOMAIN=`echo ${DOMAIN} | sed 's#http://##g' | sed 's#https://##g' | sed 's#/##g' | tr -d '\r'`
  
  # https://stackoverflow.com/questions/39025969/aadsts50011-the-reply-address-is-not-using-a-secure-schemeazure.
  if curl https://${DOMAIN} 2>&1 | grep -qE "curl\: \([0-9]+\)"
  then
  echo "Only support HTTPS!"
  exit 1
  fi
  sed -i "s#ju.tn#${DOMAIN}#g" "$PWD/view/admin/install/install_1.php"
  sed -i "s#ju.tn#${DOMAIN}#g" "$PWD/controller/AdminController.php"
fi

if find / -type d -name "oneindex-config" 2>&1 | grep -v "denied" | grep -q "config"
then
  MOUNT_PATH=$(dirname `find / -type d -name "oneindex-config" 2>&1 | grep -v "denied" | head -n 1`)
  yes | cp -rf $MOUNT_PATH/oneindex-config/* $PWD/config
  yes | cp -rf $MOUNT_PATH/oneindex-cache/* $PWD/cache
  MPATH=$MOUNT_PATH
fi

if [ -z "${MPATH}" ]
then
  MPATH=/data
fi

echo "0 * * * * yes | cp -rf $PWD/config/* ${MPATH}/oneindex-config" >> "$PWD/crontab"
echo "*/20 * * * * yes | cp -rf $PWD/cache/* ${MPATH}/oneindex-cache" >> "$PWD/crontab"

if [ "${RCONFIG}" ]
then
  curl -L -o rclone.conf "${RCONFIG}"
  NETDISK=`cat rclone.conf | grep "\[" | head -n 1 | sed -E 's/\[(.*?)\]/\1/' | tr -d '\r'`
  $PWD/rclone copy $NETDISK:/rclone/config $PWD/config
  $PWD/rclone copy $NETDISK:/rclone/cache $PWD/cache
  echo "0 * * * * $PWD/rclone sync $PWD/config/ $NETDISK:/rclone/config" >> $PWD/crontab
  echo "*/20 * * * * $PWD/rclone sync $PWD/cache/ $NETDISK:/rclone/cache" >> $PWD/crontab
fi

if [ "${ADMIN_PASS}" ]
then
  sed -i "s#:oneindex)#:${ADMIN_PASS})#g" $PWD/view/admin/install/install_3.php
  sed -i "s#'password' => 'oneindex#'password' => '${ADMIN_PASS}#g" $PWD/controller/AdminController.php
else
  sed -i "s#:oneindex)#:yhiblog)#g" $PWD/view/admin/install/install_3.php
  sed -i "s#'password' => 'oneindex'#'password' => 'yhiblog'#g" $PWD/controller/AdminController.php
fi

php-fpm7 -D
echo "0 * * * * php $PWD/one.php token:refresh" >> $PWD/crontab
echo "*/1 * * * * php $PWD/one.php cache:refresh" >> $PWD/crontab
nohup $PWD/supercronic $PWD/crontab > /dev/null 2>&1 &
$PWD/caddy --conf $PWD/Caddyfile
