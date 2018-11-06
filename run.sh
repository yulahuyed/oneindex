#!/bin/bash


mv -f /home/oneindex-master/* /home/oneindex
rm -rf /home/oneindex-master
# https://github.com/Azure-Samples/active-directory-dotnet-webapp-roleclaims/issues/19

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

echo "0 * * * * php $PWD/one.php token:refresh" > /home/crontab
echo "*/1 * * * * php $PWD/one.php cache:refresh" >> /home/crontab

if [ "${RCONFIG}" ] && [ ! -f "$PWD/config/rclone.conf" ]
then
  mkdir -p $PWD/config
  curl -L -o "$PWD/config/rclone.conf" "${RCONFIG}"
  NETDISK=`cat $PWD/config/rclone.conf | grep "\[" | head -n 1 | sed -E 's/\[(.*?)\]/\1/' | tr -d '\r'`
  $PWD/rclone copy $NETDISK:/rclone/config $PWD/config
  $PWD/rclone copy $NETDISK:/rclone/cache $PWD/cache
  echo "0 * * * * /home/rclone sync $PWD/config/ $NETDISK:/rclone/config" >> /home/crontab
  echo "*/20 * * * * /home/rclone sync $PWD/cache/ $NETDISK:/rclone/cache" >> /home/crontab
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

nohup /home/supercronic /home/crontab > /dev/null 2>&1 &
/home/caddy --conf /home/Caddyfile
