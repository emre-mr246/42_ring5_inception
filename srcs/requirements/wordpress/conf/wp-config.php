<?php

define( 'DB_NAME', '${WORDPRESS_DB_NAME}' );
define( 'DB_USER', '${WORDPRESS_DB_USER}' );
define( 'DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}' );
define( 'DB_HOST', '${WORDPRESS_DB_HOST}' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

define( 'AUTH_KEY',         '${AUTH_KEY}' );
define( 'SECURE_AUTH_KEY',  '${SECURE_AUTH_KEY}' );
define( 'LOGGED_IN_KEY',    '${LOGGED_IN_KEY}' );
define( 'NONCE_KEY',        '${NONCE_KEY}' );
define( 'AUTH_SALT',        '${AUTH_SALT}' );
define( 'SECURE_AUTH_SALT', '${SECURE_AUTH_SALT}' );
define( 'LOGGED_IN_SALT',   '${LOGGED_IN_SALT}' );
define( 'NONCE_SALT',       '${NONCE_SALT}' );

$table_prefix = 'wp_';

define( 'WP_HOME', 'https://${DOMAIN_NAME}' );
define( 'WP_SITEURL', 'https://${DOMAIN_NAME}' );

define( 'FORCE_SSL_ADMIN', true );

define( 'FTP_HOST', 'ftp-server:2121' );
define( 'FTP_BASE', '/' );
define( 'FTP_CONTENT_DIR', '/wp-content/' );
define( 'FTP_PLUGIN_DIR', '/wp-content/plugins/' );
define( 'FTP_USER', 'ftpuser' );
define( 'FTP_PASS', '${FTP_PASS}' );

define( 'WP_REDIS_HOST', 'redis' );
define( 'WP_REDIS_PORT', 6379 );
define( 'WP_REDIS_PASSWORD', '${REDIS_PASS}' );
define( 'WP_REDIS_DATABASE', 0 );
define( 'WP_CACHE', true );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
