FROM php:7.1

MAINTAINER huangzhhui <huangzhwork@gmail.com>

RUN /bin/cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo 'Asia/Shanghai' > /etc/timezone

RUN apt-get update \
    && apt-get install -y \
        curl \
        wget \
        git \
        vim \
        zip \
    && apt-get clean

ADD ./composer.phar /usr/local/bin/composer
RUN chmod 755 /usr/local/bin/composer \
    && composer self-update --clean-backups

RUN wget https://github.com/redis/hiredis/archive/v0.13.3.tar.gz -O hiredis.tar.gz \
    && mkdir -p hiredis \
    && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
    && rm hiredis.tar.gz \
    && ( \
        cd hiredis \
        && make -j$(nproc) \
        && make install \
        && ldconfig \
    ) \
    && rm -r hiredis
RUN wget https://github.com/swoole/swoole-src/archive/v2.0.9.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-async-redis --enable-mysqlnd --enable-coroutine \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole
RUN pecl install inotify \
    && docker-php-ext-enable inotify

ADD . /var/www/swoft

WORKDIR /var/www/swoft
RUN composer install --no-dev \
    && composer dump-autoload -o \
    && composer clearcache

EXPOSE 80

CMD ["php", "/var/www/swoft/bin/swoft.php", "start"]