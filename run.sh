#!/bin/bash

if [ "${DOMAIN}" ]
then
  sed -i "s#https://ju.tn/#${DOMAIN}#g" /home/oneindex/view/admin/install/install_1.php
  sed -i "s#https://ju.tn/#${DOMAIN}#g" /home/oneindex/controller/AdminController.php
fi

php-fpm7 -D
echo "0 * * * * php /home/oneindex/one.php token:refresh" > /home/oneindex/crontab
echo "*/1 * * * * php /home/oneindex/one.php cache:refresh" >> /home/oneindex/crontab
nohup /home/oneindex/supercronic /home/oneindex/crontab > /dev/null 2>&1 &
/home/oneindex/caddy --conf /home/oneindex/Caddyfile
