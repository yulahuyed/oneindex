FROM alpine:latest

ENV RCLONE_CONFIG=/home/oneindex/rclone.conf

RUN apk add --no-cache bash curl php7 php7-curl php7-fpm php7-cli php7-json unzip

RUN mkdir -p /home/oneindex

WORKDIR /home/oneindex

RUN curl -L -o caddy.tar.gz "https://caddyserver.com/download/linux/amd64?license=personal&telemetry=off"
RUN tar -xzf caddy.tar.gz
RUN rm -rf caddy.tar.gz

RUN curl -L -o supercronic "https://github.com/aptible/supercronic/releases/download/v0.1.6/supercronic-linux-amd64"

RUN curl -L -o rclone.zip "https://downloads.rclone.org/v1.43.1/rclone-v1.43.1-linux-amd64.zip"
RUN unzip rclone.zip
RUN mv rclone*/* /home/oneindex/
RUN rm -rf rclone.zip rclone*/

RUN curl -L -o oneindex.zip https://github.com/donwa/oneindex/archive/master.zip
RUN unzip oneindex.zip
RUN mv oneindex-master/* /home/oneindex/
RUN rm -rf oneindex.zip oneindex-master

COPY ./Caddyfile /home/oneindex/Caddyfile
COPY ./run.sh /home/oneindex/run.sh

RUN sed -i "s/127.0.0.1:9000/9000/g" /etc/php7/php-fpm.d/www.conf
RUN sed -i 's/self::$client_secret/urlencode(self::$client_secret)/g' /home/oneindex/lib/onedrive.php

RUN chmod -R 777 /home/oneindex
RUN chmod -R 777 /etc/php7
RUN chmod -R 777 /var/log

EXPOSE 8080

CMD ["/home/oneindex/run.sh"]

