#!/usr/bin/env bash

provision apache mysql

config=`find /vagrant -name 'web.config' -print -quit`
DEST='/vagrant/drupal'

function install-drupal () {
    local version=$1

    if [[ -z "$config" ]]; then
        echo "Deploying Drupal installation..."

        local TMPDIR=`mktemp --directory`

        local url="http://ftp.drupal.org/files/projects/drupal-${version}.tar.gz"
        echo "Loading from $url ..."
        wget --quiet --no-http-keep-alive -O - $url \
            | tar -C $TMPDIR -xzf -

        local SOURCE="${TMPDIR}/drupal-${version}"

        mkdir $DEST 2>/dev/null
        cp -r $SOURCE/* $DEST
        rm -r $TMPDIR

        service apache2 restart >/dev/null
    fi
}

#setup apache to work with Drupal
has apache2-mpm-prefork libapache2-mod-php5 php5-mysql php5-gd php5-curl || {
    echo "Setting up Drupal requirements..."

    can apt-add-repository || apt-install python-software-properties
    apt-add-repository ppa:ondrej/php5 >/dev/null
    apt-update

    setup-apache prefork $DEST

    apt-install libapache2-mod-php5 php5-mysql php5-gd php5-curl

    site=/etc/apache2/sites-available/000-default.conf
    [ -f $site.orig ] || {
      sed -i.orig 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www/g' $site
    }
    a2enmod rewrite >/dev/null

    service apache2 restart >/dev/null
}
