FROM php:7.4.0-fpm-alpine
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apk add --no-cache --update libmemcached-libs zlib
RUN set -xe && \
    cd /tmp/ && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS && \
    apk add --no-cache --update --virtual .memcached-deps zlib-dev libmemcached-dev cyrus-sasl-dev && \
    apk add --no-cache --update --virtual .php-ext-deps zlib-dev openldap-dev libpng-dev postgresql-dev sqlite-dev icu-dev libmemcached-dev && \
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
    docker-php-ext-enable igbinary memcached && \
    rm -rf /tmp/* && \
    # Install other PHP extensions
    docker-php-ext-install bcmath ldap gd pdo_pgsql pdo_sqlite pdo_mysql intl opcache && \
    apk del .memcached-deps .phpize-deps .php-ext-deps && \
    # Reinstall required packages gd:libpng, intl:icu-libs, ldap:libldap, pdo_pgsql:libpq
    apk add --no-cache libpq libpng libldap icu-libs

# Install composer and plugins
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    composer global require hirak/prestissimo --no-plugins --no-scripts && \
	cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    sed -i 's/max_execution_time = 30/max_execution_time = 600/' /usr/local/etc/php/php.ini && \
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' /usr/local/etc/php/php.ini
