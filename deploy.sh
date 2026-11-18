#!/usr/bin/env bash
#
# deploy.sh - Deploy a generated static site ZIP to an Apache (LAMP) server.
#
# Usage:
#   sudo ./deploy.sh -z site.zip -d example.com [-e admin@example.com] [-s]
#
# Options:
#   -z  Path to the ZIP produced by the generator (required)
#   -d  Domain name to serve, e.g. example.com (required)
#   -e  Email for Let's Encrypt registration (required with -s)
#   -s  Obtain and install a free HTTPS certificate via certbot
#   -h  Show this help
#
# Targets Debian/Ubuntu (apache2, a2ensite). Re-running updates the site in place.

set -euo pipefail

ZIP=""; DOMAIN=""; EMAIL=""; SSL=0

usage() { sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//'; }
die()   { echo "Error: $*" >&2; exit 1; }

while getopts "z:d:e:sh" opt; do
  case "$opt" in
    z) ZIP="$OPTARG" ;;
    d) DOMAIN="$OPTARG" ;;
    e) EMAIL="$OPTARG" ;;
    s) SSL=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

[[ $EUID -eq 0 ]]   || die "Run as root (use sudo)."
[[ -n "$ZIP" ]]     || { usage; die "-z is required."; }
[[ -f "$ZIP" ]]     || die "ZIP not found: $ZIP"
[[ -n "$DOMAIN" ]]  || { usage; die "-d is required."; }
[[ "$DOMAIN" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]] || die "Invalid domain: $DOMAIN"
if [[ $SSL -eq 1 ]]; then
  [[ -n "$EMAIL" ]] || die "-e is required with -s."
  [[ "$EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$ ]] || die "Invalid email: $EMAIL"
fi
command -v apt-get >/dev/null || die "This script supports Debian/Ubuntu only."

WEBROOT="/var/www/$DOMAIN"
CONF="/etc/apache2/sites-available/$DOMAIN.conf"

echo "==> Installing packages"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq apache2 unzip >/dev/null
if [[ $SSL -eq 1 ]]; then
  apt-get install -y -qq certbot python3-certbot-apache >/dev/null
fi

echo "==> Extracting site to $WEBROOT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q -o "$ZIP" -d "$TMP"
[[ -f "$TMP/index.html" ]] || die "ZIP does not contain index.html at its top level."

mkdir -p "$WEBROOT"
# Replace contents atomically-ish: clear old files, copy new ones.
find "$WEBROOT" -mindepth 1 -delete
cp -a "$TMP"/. "$WEBROOT"/
chown -R www-data:www-data "$WEBROOT"
find "$WEBROOT" -type d -exec chmod 755 {} +
find "$WEBROOT" -type f -exec chmod 644 {} +

echo "==> Writing Apache vhost"
a2enmod headers >/dev/null
cat > "$CONF" <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $WEBROOT

    <Directory $WEBROOT>
        Options -Indexes -FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

    ServerSignature Off
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"

    ErrorLog \${APACHE_LOG_DIR}/$DOMAIN-error.log
    CustomLog \${APACHE_LOG_DIR}/$DOMAIN-access.log combined
</VirtualHost>
EOF

a2ensite "$DOMAIN.conf" >/dev/null
apache2ctl configtest
systemctl reload apache2

if [[ $SSL -eq 1 ]]; then
  echo "==> Requesting HTTPS certificate (DNS for $DOMAIN must already point to this server)"
  certbot --apache --non-interactive --agree-tos --redirect \
    -m "$EMAIL" -d "$DOMAIN" -d "www.$DOMAIN"
fi

echo
echo "Done. Site deployed to $WEBROOT"
echo "Visit: http$([[ $SSL -eq 1 ]] && echo s)://$DOMAIN"
