# Shopware 6 auf Ubuntu Server (normale Webanwendung)

Dieses Repository dient als Grundlage für die Installation von Shopware 6 auf einem Ubuntu-Server ohne Docker. Ziel ist eine klassische Webanwendung mit:

- Ubuntu Server
- Nginx oder Apache
- PHP-FPM
- MariaDB/MySQL
- Composer
- Shopware 6

## Ziel

Shopware 6 soll wie eine normale Webanwendung auf dem Server laufen, nicht als Docker-Container. Die Konfiguration wird so vorbereitet, dass sie auf einem produktiven Ubuntu-Server mit einem Webserver, PHP und einer Datenbank betrieben werden kann.

## Voraussetzungen

- Ubuntu 22.04 LTS oder 24.04 LTS
- Root- oder sudo-Zugriff auf den Server
- Domain oder Subdomain, z. B. `shop.example.com`
- Zugang zu einem MariaDB/MySQL-Server
- Composer und PHP-Extensions für Shopware 6

## Empfohlene Server-Umgebung

- Betriebssystem: Ubuntu 22.04 LTS
- Webserver: Nginx
- PHP: 8.2 oder 8.3 je nach Shopware-Version
- Datenbank: MariaDB 10.6+
- Cache/Queue: Redis optional
- Dateisystem: `/var/www/shopware`

## Installationsschritte

### 1) Ubuntu vorbereiten

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg unzip git software-properties-common
```

### 2) PHP, MariaDB und Nginx installieren

```bash
sudo apt install -y nginx mariadb-server php8.2-fpm php8.2-cli php8.2-mysql php8.2-xml php8.2-curl php8.2-gd php8.2-intl php8.2-mbstring php8.2-zip php8.2-bcmath php8.2-soap php8.2-redis php8.2-opcache composer
```

Wenn PHP 8.2 nicht in den Paketquellen enthalten ist, alternativ:

```bash
sudo add-apt-repository ppa:ondrej/php
sudo apt update
```

### 3) MariaDB vorbereiten

```bash
sudo mysql_secure_installation
sudo mysql -u root -p
```

Beispiel:

```sql
CREATE DATABASE shopware CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'shopware'@'localhost' IDENTIFIED BY 'StrongPassword123!';
GRANT ALL PRIVILEGES ON shopware.* TO 'shopware'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 4) Anwendung anlegen

```bash
sudo mkdir -p /var/www/shopware
sudo chown -R $USER:$USER /var/www/shopware
```

### 5) Shopware herunterladen

Die bevorzugte Installationsweise ist der offizielle Shopware-Download oder das Composer-Projekt entsprechend der Shopware-Version.

Beispiel mit Composer:

```bash
cd /var/www/shopware
composer create-project shopware/platform .
```

Falls der genaue Shopware-Release aus einem Download-Archiv stammt:

```bash
cd /var/www/shopware
sudo unzip shopware-*.zip
sudo chown -R www-data:www-data /var/www/shopware
```

### 6) Nginx konfigurieren

Beispiel für eine VHost-Datei:

```nginx
server {
    listen 80;
    server_name shop.example.com;
    root /var/www/shopware/public;
    index index.php index.html;

    access_log /var/log/nginx/shopware_access.log;
    error_log /var/log/nginx/shopware_error.log;

    location / {
        try_files $uri /index.php$is_args$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, max-age=31536000, immutable";
        try_files $uri =404;
    }
}
```

Aktivieren:

```bash
sudo ln -s /etc/nginx/sites-available/shopware /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 7) PHP-FPM konfigurieren

Prüfen, ob PHP-FPM läuft:

```bash
sudo systemctl enable --now php8.2-fpm
sudo systemctl status php8.2-fpm
```

### 8) Dateirechte setzen

```bash
sudo chown -R www-data:www-data /var/www/shopware
sudo find /var/www/shopware -type d -exec chmod 755 {} \;
sudo find /var/www/shopware -type f -exec chmod 644 {} \;
sudo chmod -R 775 /var/www/shopware/var /var/www/shopware/public/media /var/www/shopware/files /var/www/shopware/config
```

### 9) Shopware-Installer starten

Nach der Webserver-Konfiguration kann die Installation über die Domain im Browser gestartet werden:

```text
https://shop.example.com
```

Dort werden die Datenbankparameter, Admin-Benutzer und die Konfiguration eingegeben.

### 10) Nach der Installation

Empfohlene Schritte:

```bash
cd /var/www/shopware
php bin/console cache:clear
php bin/console plugin:refresh
php bin/console scheduled-task:run
```

Optional:

- Redis für Cache/Session aktivieren
- Cronjobs einrichten
- SSL mit Let's Encrypt aktivieren
- Shopware-Plugins in `custom/plugins/<PluginName>` installieren

## Wichtige Hinweise

- Für Plugin-/Theme-Änderungen werden keine ZIP-Dateien verwendet.
- Dateien werden direkt in den Serverpfad deployed:

```text
custom/plugins/<Name>
```

- Für Produktiv-Deployments immer sauberer Code-Workflow mit Git und regelmäßigen Commits verwenden.

## Projektstruktur

Dieses Repository dient vor allem als Setup-Dokumentation und Automatisierungsbasis. Für die eigentliche Shopware-Installation wird der Code auf dem Ubuntu-Server in `/var/www/shopware` abgelegt.

## Changelog

Siehe [CHANGELOG.md](CHANGELOG.md).
