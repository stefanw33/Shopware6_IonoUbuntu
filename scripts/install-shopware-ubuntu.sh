#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/var/www/shopware}"
DOMAIN="${DOMAIN:-sw.projectvision.de}"
DB_NAME="${DB_NAME:-shopware}"
DB_USER="${DB_USER:-shopware}"
DB_PASSWORD="${DB_PASSWORD:-StrongPassword123!}"
PHP_VERSION="${PHP_VERSION:-8.3}"

echo "==> Updating system packages"
sudo apt update
sudo apt upgrade -y

echo "==> Installing required packages"
sudo apt install -y \
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

# Apache2 already exists and is active on the server. No Apache installation is required.

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

echo "==> Reusing existing Apache vhost"
if [ -f /etc/apache2/sites-enabled/vps.projectvision.de.conf ]; then
    echo "Using existing vhost: /etc/apache2/sites-enabled/vps.projectvision.de.conf"
    grep -n "DocumentRoot" /etc/apache2/sites-enabled/vps.projectvision.de.conf || true
    echo "IMPORTANT: update this vhost to DocumentRoot /var/www/shopware if it still points elsewhere."
else
    echo "Missing expected Apache vhost file: /etc/apache2/sites-enabled/vps.projectvision.de.conf"
    echo "Please verify your Apache configuration before continuing."
fi

sudo apache2ctl configtest || true
sudo systemctl reload apache2 || true

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
