FROM php:8.1-fpm-alpine as base

RUN apk update --no-cache && \
    apk upgrade --no-cache
RUN apk add --no-cache \
        supervisor

FROM base as build

RUN apk add --no-cache \
    $PHPIZE_DEPS \
    linux-headers
RUN apk add --no-cache \
    freetype-dev \
    jpeg-dev \
    icu-dev \
    libzip-dev

#####################################
# PHP Extensions
#####################################
# Install the PHP shared memory driver
RUN pecl install APCu && \
    docker-php-ext-enable apcu

# Install the PHP bcmath extension
RUN docker-php-ext-install bcmath

# Install for image manipulation
RUN docker-php-ext-install exif

# Install the PHP graphics library
RUN docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg
RUN docker-php-ext-install gd

# Install the PHP intl extention
RUN docker-php-ext-install intl

# Install the PHP mysqli extention
RUN docker-php-ext-install mysqli && \
    docker-php-ext-enable mysqli

# Install the PHP opcache extention
RUN docker-php-ext-enable opcache

# Install the PHP pcntl extention
RUN docker-php-ext-install pcntl

# Install the PHP pdo_mysql extention
RUN docker-php-ext-install pdo_mysql

# Install the PHP redis driver
RUN pecl install redis && \
    docker-php-ext-enable redis

# install XDebug but without enabling
RUN pecl install xdebug

# Install the PHP zip extention
RUN docker-php-ext-install zip

FROM base as target

#####################################
# Install necessary libraries
#####################################
RUN apk add --no-cache \
    freetype \
    jpeg \
    icu \
    libzip

#####################################
# Copy extensions from build stage
#####################################
COPY --from=build /usr/local/lib/php/extensions/no-debug-non-zts-20210902/* /usr/local/lib/php/extensions/no-debug-non-zts-20210902
COPY --from=build /usr/local/etc/php/conf.d/* /usr/local/etc/php/conf.d

#####################################
# Composer
#####################################
RUN curl -s http://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

#####################################
# Entrypoint
#####################################
COPY ./docker/php-fpm/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s /usr/local/bin/docker-entrypoint.sh /

WORKDIR /var/www/html
COPY . /var/www/html/

RUN composer install

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["docker-entrypoint.sh"]
