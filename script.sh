#!/bin/bash

set -eu

trap end_install EXIT

#
##
update_system() {
    #
    apt update
    apt -yqq upgrade
}

#
##
install_base_system() {
    #
    apt -yqq install --no-install-recommends apt-utils 2>&1
    apt -yqq install --no-install-recommends apt-transport-https 2>&1
    #
    apt -yqq install ca-certificates build-essential net-tools curl wget lsb-release procps 2>&1
    apt -yqq install perl unzip git nano htop iftop mariadb-client 2>&1
}

#
##
define_passwords() {
    # check if existing passwords file exists
    if [ -f /root/passwords.txt ]; then
        # load existing file
        set -o allexport
        source /root/passwords.txt
        set +o allexport
    fi
}

#
##
install_apache() {
    # apache2 and Utils
    apt -yqq install apache2 apache2-utils

    # enable apache modules
    a2enmod headers
    a2enmod rewrite

    #
    awk '/<Directory \/var\/www\/>/,/AllowOverride None/{sub("None", "All",$0)}{print}' /etc/apache2/apache2.conf > tmp.conf && mv tmp.conf /etc/apache2/apache2.conf
    
    #
    service apache2 restart

    #
    rm  -f /var/www/html/index.html
}

#
##
install_php() {
    # is PHP5
    if [ "$VERSION_ID" = "12.04" ] || [ "$VERSION_ID" = "14.04" ] || [ "$VERSION_ID" = "15.04" ]; then
        PHP_VERSION="5"
    fi

    # is PHP7
    if [ "$VERSION_ID" = "16.04" ] || [ "$VERSION_ID" = "16.10" ] || [ "$VERSION_ID" = "17.04" ] || [ "$VERSION_ID" = "17.10" ]; then
        PHP_VERSION="7.0"
    fi

    # is PHP7.2
    if [ "$VERSION_ID" = "18.04" ] || [ "$VERSION_ID" = "18.10" ]; then
        PHP_VERSION="7.2"
    fi

    # is PHP7.4
    if [ "$VERSION_ID" = "20.04" ] || [ "$VERSION_ID" = "20.10" ]; then
        PHP_VERSION="7.4"
    fi

    #

    # install PHP5
    if [ "$PHP_VERSION" = "5" ]; then
        #
        echo "Installing PHP$PHP_VERSION"
        apt -yqq install php$PHP_VERSION php$PHP_VERSION-cli
        apt -yqq install php$PHP_VERSION-{curl,gd,mcrypt,json,mysql,sqlite}
        #
        apt -yqq install libapache2-mod-php$PHP_VERSION
        #
        # enable mods
        php5enmod mcrypt

	#
        change_php_ini

        #
        service apache2 restart
    fi

    # install PHP7
    if [ "$PHP_VERSION" = "7.0" ]; then
        #
        echo "Installing PHP$PHP_VERSION"
        apt -yqq install php$PHP_VERSION php$PHP_VERSION-cli
        apt -yqq install php$PHP_VERSION-{mbstring,curl,gd,mcrypt,json,xml,mysql,sqlite}
        #
        apt -yqq install libapache2-mod-php$PHP_VERSION

	#
        change_php_ini

        #
        service apache2 restart
    fi

    # install PHP[7.2]
    if [ "$PHP_VERSION" = "7.2" ] || [ "$PHP_VERSION" = "7.4" ]; then
        #
        echo "Installing PHP$PHP_VERSION"
        apt -yqq install php$PHP_VERSION php$PHP_VERSION-cli
        apt -yqq install php$PHP_VERSION-{mbstring,curl,gd,json,xml,mysql,sqlite3,opcache,zip}
        #
        apt -yqq install libapache2-mod-php$PHP_VERSION

	#
        change_php_ini

        #
        service apache2 restart
    fi

    # install PHP[7.4]
    if [ "$PHP_VERSION" = "7.4" ]; then
        #
        echo "Installing PHP"
        apt -yqq install php php-cli
        apt -yqq install php-{common,bz2,getid3,imagick,intl,mbstring,curl,gd,json,xml,mysql,sqlite3,opcache,zip}
        #
        apt -yqq install libapache2-mod-php

        #
        change_php_ini

        #
        service apache2 restart
    fi
}

change_php_ini() {
    #
    sed -i 's/memory_limit\s*=.*/memory_limit = 1024M/g' /etc/php/$PHP_VERSION/apache2/php.ini

    sed -i 's/max_execution_time\s*=.*/max_execution_time = 300/g' /etc/php/$PHP_VERSION/apache2/php.ini

    sed -i 's/post_max_size\s*=.*/post_max_size = 128M/g' /etc/php/$PHP_VERSION/apache2/php.ini

    sed -i 's/upload_max_filesize\s*=.*/upload_max_filesize = 128M/g' /etc/php/$PHP_VERSION/apache2/php.ini

    sed -i 's/max_file_uploads\s*=.*/max_file_uploads = 5/g' /etc/php/$PHP_VERSION/apache2/php.ini

    #sed -i "s/.*upload_tmp_dir.*/upload_tmp_dir = \/tmp\/php-uploads/" /etc/php/$PHP_VERSION/apache2/php.ini
}

start_install(){
    #
    . /etc/os-release

    # check is root user
    if [[ $EUID -ne 0 ]]; then
        echo "You must be root user to install scripts."
        sudo su
    fi

    # check os is ubuntu
    if [[ $ID != "ubuntu" ]]; then
        echo "Wrong OS! Sorry only Ubuntu is supported."
        exit 1
    fi

    export DEBIAN_FRONTEND=noninteractive

    echo >&2 "Deploy-Script: [OS] $PRETTY_NAME"
}

end_install(){
    # clean up apt
    apt-get autoremove -y && apt-get autoclean -y && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    # return to dialog
    export DEBIAN_FRONTEND=dialog

    # remove script
    rm -f script.sh
}

#
##
main() {
    #
    start_install

    #
    update_system
    
    #
    install_base_system

    #
    define_passwords

    #
    install_apache
    
    #
    install_php
    
    #
    end_install

    echo >&2 "LAP install completed"
}

main
