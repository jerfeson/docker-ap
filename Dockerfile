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
RUN apt-get -y install php8.0 libapache2-mod-php8.0 php8.0-cli php8.0-common php8.0-mysql \
php8.0-curl php8.0-dev php8.0-mbstring php8.0-gd php8.0-redis php8.0-xml php8.0-zip php8.0-intl

#Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

#Install XDebug
RUN pecl install xdebug

#Configuration XDebug
RUN echo 'zend_extension=/usr/lib/php/20200930/xdebug.so' >> /etc/php/8.0/apache2/php.ini
RUN echo 'zend_extension=/usr/lib/php/20200930/xdebug.so' >> /etc/php/8.0/cli/php.ini


# Clean up
RUN rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE  80

CMD echo $XDEBUG_CONFIG >> /etc/php/8.0/apache2/php.ini && echo $PHP_XDEBUG_ENABLED >> /etc/php/8.0/apache2/php.ini && apachectl -D FOREGROUND