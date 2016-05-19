FROM ubuntu:14.04

ENV APACHE_UID 99
ENV APACHE_GID 99
ENV APACHE_RUN_USER #${APACHE_UID}
ENV APACHE_RUN_GROUP #${APACHE_GID}
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_USER webdav
ENV APACHE_PASSWD webdav


RUN groupadd webdav -g ${APACHE_GID} && useradd -r webdav -u ${APACHE_UID} -g ${APACHE_GID}
RUN mkdir -p /srv/webdav && chown $APACHE_UID /srv/webdav
RUN apt-get update
RUN apt-get install -y --no-install-recommends apache2 php5 php5-cli php5-sqlite apache2-utils && apt-get clean

# Enable modules
RUN a2enmod dav dav_fs
RUN a2enmod php5
RUN a2enmod auth_digest


# Install PHP Twigg
RUN php5 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php5 -r "if (hash_file('SHA384', 'composer-setup.php') === '92102166af5abdb03f49ce52a40591073a7b859a86e8ff13338cf7db58a19f7844fbc0bb79b2773bf30791e935dbd938') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
RUN php5 composer-setup.php
RUN php5 composer.phar require twig/twig:~1.0
RUN php -r "unlink('composer-setup.php');"

RUN rm /etc/apache2/sites-enabled/000-default.conf
RUN mkdir -p /var/lock/apache2; chown $APACHE_UID /var/lock/apache2

ADD php.ini /etc/php5/apache2/php.ini
RUN mkdir -p /etc/apache2/webdav; chown $APACHE_UID /etc/apache2/webdav
ADD apache2.conf /etc/apache2/apache2.conf
ADD webdav/webdav.conf /etc/apache2/webdav/webdav.conf
ADD webdav/webdav.passwd /etc/apache2/webdav/webdav.passwd

VOLUME ["/srv/webdav"]
EXPOSE 80

CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
