# GuestPriceVisibility

Blendet Preise in der Shopware-Storefront für nicht angemeldete Besucher aus. Angemeldete Kunden sehen die Preise unverändert.

## Installation auf dem Server

Das Plugin wird direkt in diesen Serverpfad deployed:

```text
custom/plugins/GuestPriceVisibility
```

Danach im Shopware-Projekt ausführen:

```bash
php bin/console plugin:refresh
php bin/console plugin:install --activate GuestPriceVisibility
php bin/console cache:clear
```

## Verhalten

- Gastbesucher sehen statt der Preise den Hinweis `Preis nach Anmeldung sichtbar`.
- Eingeloggte Kunden sehen die normalen Preise.
- Die Lösung verändert keine Produktpreise und keine Warenkorbberechnung.
- Docker, Apache und PHP werden durch das Plugin nicht verändert.

Nach der Aktivierung sollte die Storefront als Gast und anschließend in einem Kundenkonto getestet werden. Browser- und Shopware-Caches müssen dabei berücksichtigt werden.