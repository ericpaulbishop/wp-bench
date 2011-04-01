#!/bin/bash

MODE="$1"

#contants to use to initialize our test WP installation
DB_ROOT_PASSWORD="password"
WP_TITLE="Benchmark Blog"
WP_USER="bench"
WP_PASS="benchpass"
WP_EMAIL="thisisadummybenchemail@thisisadummybenchemail.com"


if [ "$MODE" = "linode" ] ; then
	
	source ./linode-bash-library.sh
	source ./finish-apache-wp-install.sh 

	vhost=$(get_rdns_primary_ip)
	if [ -z "$vhost" ] ; then
		vhost=$(system_primary_ip)
	fi
	if [ -z "$vhost" ] ; then
		vhost="127.0.0.1"
	fi

	system_update
	postfix_install_loopback_only
	mysql_install "$DB_ROOT_PASSWORD" && mysql_tune 40
	php_install_with_apache && php_tune
	apache_install && apache_tune 40 && apache_virtualhost "$vhost"
	goodstuff
	wordpress_install "$vhost"
	finish_apache_wp_install "$vhost" "$WP_TITLE" "$WP_USER" "$WP_PASS" "$WP_EMAIL"
	restartServices

elif [ "$MODE" = "redcloud" ] ; then
	
	aptitude -y install git
	git clone git://github.com/ericpaulbishop/redcloud.git
	cd redcloud
	git checkout 2011
	./install.sh
	source /usr/local/lib/redcloud/redcloud.sh


	#updates packages to latest versions
	upgrade_system

	
	#port 22=ssh; 80=http
	set_open_ports 22 80


	# Add an admin user
	# Not strictly necessary for bench script, 
	# but it's just good practice to alwas have a non-root user
	# Last arg indicates that this is an admin
	add_user "bench" "bench_pass" "1"


	#install mysql, let it use up to 40% of memory
	mysql_install "$DB_ROOT_PASSWORD"
	mysql_tune 40


	#install nginx, along with php but not passenger(ruby) or perl
	nginx_install "www-data"  "www-data" "1" "0" "0"

	#install wordpress
	better_wordpress_install "$DB_ROOT_PASSWORD" "default" "$WP_USER" "$WP_PASS" "$WP_TITLE" "$WP_EMAIL"


else 
	echo "INVALID TEST MODE : must specify 'linode' or 'redcloud'"
fi
