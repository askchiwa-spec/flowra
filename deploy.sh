#!/bin/bash
# ═══════════════════════════════════════════════════════
# FlowrA Deployment Script — flowratech.com
# Run on VPS as root. Safe alongside existing n8n setup.
# ═══════════════════════════════════════════════════════
set -e

DOMAIN="flowratech.com"
WWW="www.flowratech.com"
REPO="https://github.com/askchiwa-spec/flowra"
WEBROOT="/var/www/flowra"
NGINX_CONF="/etc/nginx/sites-available/flowra"

echo "▶ Step 1: Installing nginx and certbot..."
apt-get update -qq
apt-get install -y nginx certbot python3-certbot-nginx git

echo "▶ Step 2: Creating web directory..."
mkdir -p $WEBROOT

echo "▶ Step 3: Cloning site from GitHub..."
if [ -d "$WEBROOT/.git" ]; then
  echo "  Repo exists — pulling latest..."
  cd $WEBROOT && git pull origin main
else
  git clone $REPO $WEBROOT
fi

echo "▶ Step 4: Writing nginx config..."
cat > $NGINX_CONF << 'NGINXCONF'
server {
    listen 80;
    listen [::]:80;
    server_name flowratech.com www.flowratech.com;
    root /var/www/flowra;
    index index.html;

    gzip on;
    gzip_vary on;
    gzip_types text/css application/javascript image/png image/svg+xml;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(css|js|woff2|woff|ttf)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location ~* \.(png|jpg|jpeg|gif|svg|ico|webp)$ {
        expires 6M;
        add_header Cache-Control "public, max-age=15552000";
        access_log off;
    }

    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    location ~ /\. { deny all; }

    access_log /var/log/nginx/flowra_access.log;
    error_log  /var/log/nginx/flowra_error.log;
}
NGINXCONF

echo "▶ Step 5: Enabling site..."
ln -sf $NGINX_CONF /etc/nginx/sites-enabled/flowra
nginx -t && systemctl reload nginx

echo "▶ Step 6: SSL certificate (Let's Encrypt)..."
certbot --nginx -d $DOMAIN -d $WWW \
  --non-interactive --agree-tos \
  -m business@flowratech.com \
  --redirect

echo "▶ Step 7: Final nginx reload..."
systemctl reload nginx

echo ""
echo "✅ DONE — https://www.flowratech.com is live!"
echo ""
echo "To update the site in future, run:"
echo "  cd /var/www/flowra && git pull origin main && systemctl reload nginx"
