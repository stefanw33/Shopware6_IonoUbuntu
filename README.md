# Shopware 6 auf Ubuntu Server (normale Webanwendung)

Dieses Repository dient als Grundlage für die Installation von Shopware 6 auf einem Ubuntu-Server ohne Docker. Ziel ist eine klassische Webanwendung mit:

- Ubuntu Server
- bereits vorhandener Apache2
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
- Webserver: bereits vorhandener Apache2
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

### 2) Nur PHP und MariaDB installieren

Apache2 läuft bereits auf dem Server. Deshalb installieren wir nur die für Shopware benötigten PHP- und Datenbankpakete:

```bash
sudo apt install -y mariadb-server php8.3-fpm php8.3-cli php8.3-mysql php8.3-xml php8.3-curl php8.3-gd php8.3-intl php8.3-mbstring php8.3-zip php8.3-bcmath php8.3-soap php8.3-redis php8.3-opcache composer
```

Wenn PHP 8.3 nicht in den Paketquellen enthalten ist, alternativ:

```bash
sudo add-apt-repository ppa:ondrej/php
sudo apt update
```

Prüfen, ob die vorhandenen Apache-Hosts bereits auf das Webroot zeigen:

```bash
sudo apache2ctl -S
ls -l /etc/apache2/sites-enabled/
```

In deinem Fall zeigt der vorhandene Host bereits auf:

```text
/var/www/vps.projectvision.de
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

In diesem Setup bleibt der Apache-Host aktiv, aber das Shopware-Projekt liegt im separaten Webroot `/var/www/shopware`:

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

### 6) Vorhandene Apache-Host-Konfiguration mit eigenem Webroot nutzen

Auf deinem Server läuft Apache bereits. Der vorhandene Host bleibt unverändert bestehen, aber wir verwenden als Shopware-Webroot das separates Verzeichnis `/var/www/shopware`.

Prüfen:

```bash
sudo apache2ctl -S
sudo grep -n "DocumentRoot" /etc/apache2/sites-enabled/vps.projectvision.de.conf
```

Wenn der aktive Host selbst noch auf `/var/www/vps.projectvision.de` zeigt, müssen wir ihn nur so anpassen, dass er auf `/var/www/shopware` zeigt. Das ist die einzige Apache-Änderung, keine Neuinstallation.

Beispiel für die Anpassung:

```apache
DocumentRoot /var/www/shopware
<Directory /var/www/shopware>
    Options FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
```

### 7) PHP-FPM konfigurieren

Prüfen, ob PHP-FPM läuft:

```bash
sudo systemctl enable --now php8.3-fpm
sudo systemctl status php8.3-fpm
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
https://sw.projectvision.de
```

Dort werden die Datenbankparameter, Admin-Benutzer und die Konfiguration eingegeben.

### 10) Nach der Installation

Empfohlene Schritte:

```bash
cd /var/www/vps.projectvision.de
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

Dieses Repository dient vor allem als Setup-Dokumentation und Automatisierungsbasis. Für die eigentliche Shopware-Installation wird der Code auf dem Ubuntu-Server in `/var/www/shopware` abgelegt und über den vorhandenen Apache-Host ausgeliefert.

## Changelog

Siehe [CHANGELOG.md](CHANGELOG.md).
