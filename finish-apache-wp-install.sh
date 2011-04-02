#!/bin/bash

source ./linode-bash-library.sh

function finish_apache_wp_install
{
	if [ ! -n "$1" ]; then
		echo "wordpress_install() requires the vitualhost as its first argument"
		return 1;
	fi
	WP_DOMAIN="$1"
	WP_TITLE="$2"
	WP_USER="$3"
	WP_PASS="$4"
	WP_EMAIL="$5"


	VPATH=$(apache_virtualhost_get_docroot $WP_DOMAIN | sed 's/\/$//g')
	

	mv "$VPATH/wordpress/"* "$VPATH/"
	cd "$VPATH/wp-admin/"
	echo '<?php' >wpinst.php
	echo "define( 'WP_SITEURL', 'http://$WP_DOMAIN' );" >>wpinst.php

	cat << 'EOF' >>wpinst.php
define( 'WP_INSTALLING', true );

/** Load WordPress Bootstrap */
require_once( dirname( dirname( __FILE__ ) ) . '/../wp-load.php' );

/** Load WordPress Administration Upgrade API */
require_once( dirname( __FILE__ ) . '/includes/upgrade.php' );

/** Load wpdb */
require_once(dirname(dirname(__FILE__)) . '/../wp-includes/wp-db.php');




// Let's check to make sure WP isn't already installed.
if ( is_blog_installed() ) {
	die( '<h1>' . __( 'Already Installed' ) . '</h1><p>' . __( 'You appear to have already installed WordPress. To reinstall please clear your old database tables first.' ) . '</p><p class="step"><a href="../wp-login.php" class="button">' . __('Log In') . '</a></p></body></html>' );
}
// Let's check to make sure WP isn't already installed.
if ( is_blog_installed() ) {
	die( '<h1>' . __( 'Already Installed' ) . '</h1><p>' . __( 'You appear to have already installed WordPress. To reinstall please clear your old database tables first.' ) . '</p><p class="step"><a href="../wp-login.php" class="button">' . __('Log In') . '</a></p></body></html>' );
}

$php_version    = phpversion();
$mysql_version  = $wpdb->db_version();
$php_compat     = version_compare( $php_version, $required_php_version, '>=' );
$mysql_compat   = version_compare( $mysql_version, $required_mysql_version, '>=' ) || file_exists( WP_CONTENT_DIR . '/db.php' );

if ( !$mysql_compat && !$php_compat )
	$compat = sprintf( __('You cannot install because <a href="http://codex.wordpress.org/Version_%1$s">WordPress %1$s</a> requires PHP version %2$s or higher and MySQL version %3$s or higher. You are running PHP version %4$s and MySQL version %5$s.'), $wp_version, $required_php_version, $required_mysql_version, $php_version, $mysql_version );
elseif ( !$php_compat )
	$compat = sprintf( __('You cannot install because <a href="http://codex.wordpress.org/Version_%1$s">WordPress %1$s</a> requires PHP version %2$s or higher. You are running version %3$s.'), $wp_version, $required_php_version, $php_version );
elseif ( !$mysql_compat )
	$compat = sprintf( __('You cannot install because <a href="http://codex.wordpress.org/Version_%1$s">WordPress %1$s</a> requires MySQL version %2$s or higher. You are running version %3$s.'), $wp_version, $required_mysql_version, $mysql_version );

if ( !$mysql_compat || !$php_compat ) {
	die('<h1>' . __('Insufficient Requirements') . '</h1><p>' . $compat . '</p></body></html>');
}
EOF
	echo "\$weblog_title=\"$WP_TITLE\";"  >> wpinst.php
	echo "\$user_name=\"$WP_USER\";"      >> wpinst.php
	echo "\$admin_password=\"$WP_PASS\";" >> wpinst.php
	echo "\$admin_email=\"$WP_EMAIL\";"   >> wpinst.php
	echo "\$public=1;"                    >> wpinst.php
	cat << 'EOF' >>wpinst.php

$result = wp_install($weblog_title, $user_name, $admin_email, $public, '', $admin_password);
extract( $result, EXTR_SKIP );

?>
EOF

	php < wpinst.php
	rm -rf wpinst.php
	cd ..

}
