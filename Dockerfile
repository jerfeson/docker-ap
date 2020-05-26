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
RUN apt-get -y install php5.6 libapache2-mod-php5.6 php5.6-cli php5.6-common php5.6-mysql \
php5.6-curl php5.6-dev php5.6-mbstring php5.6-gd php5.6-json php5.6-redis php5.6-xml php5.6-zip php5.6-intl

#Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#Install XDebug
RUN pecl install xdebug-2.5.5

#Configuration XDebug
RUN echo 'zend_extension=/usr/lib/php/20131226/xdebug.so' >> /etc/php/5.6/apache2/php.ini
RUN echo 'zend_extension=/usr/lib/php/20131226/xdebug.so' >> /etc/php/5.6/cli/php.ini

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
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > /etc/php/5.6/apache2/conf.d/blackfire.ini

# Clean up
RUN rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE  80

CMD echo $XDEBUG_CONFIG >> /etc/php/7.2/apache2/php.ini && echo $PHP_XDEBUG_ENABLED >> /etc/php/7.2/apache2/php.ini && apachectl -D FOREGROUND