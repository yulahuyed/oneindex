#!/bin/bash

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
  yes | cp -rf $MOUNT_PATH/oneindex-config $PWD/config
  yes | cp -rf $MOUNT_PATH/oneindex-cache $PWD/cache
  echo "0 * * * * yes | cp -rf $PWD/config $MOUNT_PATH/oneindex-config" >> "$PWD/crontab"
  echo "0 * * * * yes | cp -rf $PWD/cache $MOUNT_PATH/oneindex-cache" >> "$PWD/crontab"
fi

if [ -z "${MPATH}" ]
then
  MPATH=/data
fi

echo "0 * * * * yes | cp -rf $PWD/config ${MPATH}/oneindex-config" >> "$PWD/crontab"
echo "0 * * * * yes | cp -rf $PWD/cache ${MPATH}/oneindex-cache" >> "$PWD/crontab"

if [ "${RCONFIG}" ]
then
  curl -L -o rclone.conf "${RCONFIG}"
  NETDISK=`cat rclone.conf | grep "\[" | head -n 1 | sed -E 's/\[(.*?)\]/\1/' | tr -d '\r'`
  /home/oneindex/rclone copy $NETDISK:/rclone/config /home/oneindex/config
  /home/oneindex/rclone copy $NETDISK:/rclone/cache /home/oneindex/cache
  echo "0 * * * * /home/oneindex/rclone sync /home/oneindex/config/ $NETDISK:/rclone/config" >> /home/oneindex/crontab
  echo "0 * * * * /home/oneindex/rclone sync /home/oneindex/cache/ $NETDISK:/rclone/cache" >> /home/oneindex/crontab
fi

if [ "${ADMIN_PASS}" ]
then
  sed -i "s#:oneindex)#:${ADMIN_PASS})#g" /home/oneindex/view/admin/install/install_3.php
  sed -i "s#'password' => 'oneindex#'password' => '${ADMIN_PASS}#g" /home/oneindex/controller/AdminController.php
else
  sed -i "s#:oneindex)#:yhiblog)#g" /home/oneindex/view/admin/install/install_3.php
  sed -i "s#'password' => 'oneindex'#'password' => 'yhiblog'#g" /home/oneindex/controller/AdminController.php
fi

php-fpm7 -D
echo "0 * * * * php /home/oneindex/one.php token:refresh" >> /home/oneindex/crontab
echo "*/1 * * * * php /home/oneindex/one.php cache:refresh" >> /home/oneindex/crontab
nohup /home/oneindex/supercronic /home/oneindex/crontab > /dev/null 2>&1 &
/home/oneindex/caddy --conf /home/oneindex/Caddyfile
