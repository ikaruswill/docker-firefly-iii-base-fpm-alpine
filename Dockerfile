FROM php:7.4-fpm-alpine
ENV COMPOSER_ALLOW_SUPERUSER=1

# Install PHP Extensions (igbinary & memcached)
RUN apk add --no-cache --update libmemcached-libs zlib
RUN set -xe && \
    cd /tmp/ && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS && \
    apk add --no-cache --update --virtual .memcached-deps zlib-dev libmemcached-dev cyrus-sasl-dev && \
# Install igbinary (memcached's deps)
    pecl install igbinary && \
# Install memcached
    ( \
        pecl install --nobuild memcached && \
        cd "$(pecl config-get temp_dir)/memcached" && \
        phpize && \
        ./configure --enable-memcached-igbinary && \
        make -j$(nproc) && \
        make install && \
        cd /tmp/ \
    ) && \
# Enable PHP extensions
    docker-php-ext-enable igbinary memcached && \
    rm -rf /tmp/* && \
    apk del .memcached-deps .phpize-deps

# Install other PHP Extensions
RUN apk add --no-cache --update --virtual .php-ext-deps zlib-dev openldap-dev libpng-dev postgresql-dev sqlite-dev icu-dev libmemcached-dev && \
    docker-php-ext-install bcmath ldap gd pdo_pgsql pdo_sqlite pdo_mysql intl opcache && \
    apk del .php-ext-deps

# Install composer and plugins
RUN apk add --no-cache composer && \
    composer global require hirak/prestissimo --no-plugins --no-scripts && \
	cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i 's/max_execution_time = 30/max_execution_time = 600/' /usr/local/etc/php/php.ini && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' /usr/local/etc/php/php.ini
