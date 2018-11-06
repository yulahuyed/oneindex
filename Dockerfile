FROM alpine:latest
MAINTAINER yhiblog <shui.azurewebsites.net>

ENV RCLONE_CONFIG=/home/oneindex/config/rclone.conf

RUN apk add --no-cache bash curl php7 php7-curl php7-fpm php7-cli php7-json unzip


WORKDIR /home

RUN curl -L -o caddy.tar.gz "https://caddyserver.com/download/linux/amd64?license=personal&telemetry=off"
RUN tar -xzf caddy.tar.gz
RUN rm -rf caddy.tar.gz

RUN SCVERSION=`curl -L https://github.com/aptible/supercronic/releases 2>&1 | grep amd64 | head -n 1 | awk -F "href" '{print $2}' | awk -F'"' '{print $2}'` && curl -L -o supercronic "https://github.com$SCVERSION"

RUN RCVERSION=`curl -L "https://rclone.org/downloads/" 2>&1 | grep "linux-amd64" | head -n 1 | awk -F "href" '{print $2}' | awk -F'"' '{print $2}'` && curl -L -o rclone.zip "$RCVERSION"
RUN unzip rclone.zip
RUN mv rclone*/* /home/
RUN rm -rf rclone.zip rclone*/


COPY ./Caddyfile /home/Caddyfile
COPY ./run.sh /home/run.sh

RUN sed -i "s/127.0.0.1:9000/9000/g" /etc/php7/php-fpm.d/www.conf



RUN mkdir /home/oneindex && chmod -R 777 /home/oneindex
WORKDIR /home/oneindex
RUN curl -L -o /home/oneindex.zip https://github.com/donwa/oneindex/archive/master.zip
RUN cd /home && unzip oneindex.zip
RUN sed -i 's/= self::$client_secret/= urlencode(self::$client_secret)/g' /home/oneindex-*/lib/onedrive.php
RUN rm -rf /home/oneindex.zip
RUN chmod -R 777 /home
RUN chmod -R 777 /etc/php7
RUN chmod -R 777 /var/log
EXPOSE 8080

CMD ["/home/run.sh"]
