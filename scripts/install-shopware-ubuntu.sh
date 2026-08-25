#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/shopware}"
DOMAIN="${DOMAIN:-shop.example.com}"
DB_NAME="${DB_NAME:-shopware}"
DB_USER="${DB_USER:-shopware}"
DB_PASSWORD="${DB_PASSWORD:-StrongPassword123!}"
PHP_VERSION="${PHP_VERSION:-8.2}"

echo "==> Updating system packages"
sudo apt update
sudo apt upgrade -y

echo "==> Installing required packages"
sudo apt install -y \
    nginx \
    mariadb-server \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-opcache \
    composer \
    unzip \
    curl \
    git

echo "==> Configuring MariaDB"
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "==> Creating application directory"
sudo mkdir -p "${APP_ROOT}"
sudo chown -R "$USER:www-data" "${APP_ROOT}"

echo "==> Downloading Shopware"
cd "${APP_ROOT}"
# Replace with the actual Shopware release or Composer install command for your version.
# Example for Composer-based installation:
# composer create-project shopware/platform .

echo "==> Creating nginx vhost"
sudo tee /etc/nginx/sites-available/shopware >/dev/null <<EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root ${APP_ROOT}/public;
    index index.php index.html;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/shopware /etc/nginx/sites-enabled/shopware
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx

echo "==> Enabling PHP-FPM"
sudo systemctl enable --now php${PHP_VERSION}-fpm

echo "==> Setting permissions"
sudo chown -R www-data:www-data "${APP_ROOT}"
sudo find "${APP_ROOT}" -type d -exec chmod 755 {} \;
sudo find "${APP_ROOT}" -type f -exec chmod 644 {} \;
sudo chmod -R 775 "${APP_ROOT}/var" "${APP_ROOT}/public/media" "${APP_ROOT}/files" "${APP_ROOT}/config"

echo "==> Installation checklist"
echo "1. Download and install the actual Shopware release into ${APP_ROOT}"
echo "2. Open https://${DOMAIN} and complete the Shopware setup wizard"
echo "3. Enable SSL, cron jobs and plugin deployment under custom/plugins/<Name>"
