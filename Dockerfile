FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive

#Updating operating system
RUN apt-get update && apt-get -y upgrade && apt-get -y dist-upgrade

##Installing essential packages
RUN apt-get -y install apt-utils software-properties-common curl bash-completion vim git supervisor zip unzip

#configure time zone
RUN ln -f -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

#Apache
RUN apt-get -y install apache2
RUN  a2enmod rewrite

##Adding PHP repository
RUN add-apt-repository -y ppa:ondrej/php && apt-get update

#Installing PHP and extensions
RUN apt-get -y install php7.2 libapache2-mod-php7.2 php7.2-cli php7.2-common php7.2-mysql \
php7.2-curl php7.2-dev php7.2-mbstring php7.2-gd php7.2-json php7.2-redis php7.2-xml php7.2-zip php7.2-intl

#Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#Install XDebug
RUN pecl install xdebug-2.9.5

#Configuration XDebug
RUN echo 'zend_extension=/usr/lib/php/20170718/xdebug.so' >> /etc/php/7.2/apache2/php.ini
RUN echo 'zend_extension=/usr/lib/php/20170718/xdebug.so' >> /etc/php/7.2/cli/php.ini

# Quality tools
RUN USERNAME=$('whoami') && composer global require squizlabs/php_codesniffer=*  phpcompatibility/php-compatibility=* \
       friendsofphp/php-cs-fixer=* phpmd/phpmd=* \
    && export PATH=/$USERNAME/.composer/vendor/bin:$PATH \
    && phpcs --config-set installed_paths /$USERNAME/.composer/vendor/phpcompatibility/php-compatibility/ \
    && phpcs -i

#Blackfire.io
RUN mkdir "/conf.d" && version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/amd64/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > /etc/php/7.2/apache2/conf.d/blackfire.ini

# Clean up
RUN rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE  80

CMD echo $XDEBUG_CONFIG >> /etc/php/7.2/apache2/php.ini && echo $PHP_XDEBUG_ENABLED >> /etc/php/7.2/apache2/php.ini && apachectl -D FOREGROUND