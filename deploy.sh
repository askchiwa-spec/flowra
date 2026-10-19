#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════
# deploy.sh — FlowrA website · flowratech.com
# Run on the VPS as root:  sudo bash /var/www/flowra/deploy.sh
# Idempotent. Safe to re-run. Shares the box with other nginx sites:
# this script only touches sites-available/flowra and reloads nginx
# after `nginx -t` passes, so a bad config never takes anything down.
# ═══════════════════════════════════════════════════════
set -euo pipefail

DOMAIN="flowratech.com"
WWW="www.flowratech.com"
REPO="https://github.com/askchiwa-spec/flowra.git"
BRANCH="main"
WEBROOT="/var/www/flowra"
NGINX_CONF="/etc/nginx/sites-available/flowra"
CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
CERT_EMAIL="business@flowratech.com"

log() { printf '\n▶ %s\n' "$*"; }
die() { printf '\n✗ %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "Run as root (sudo)."

log "1/6 Packages"
need=()
for p in nginx certbot python3-certbot-nginx git curl; do
  dpkg -s "$p" >/dev/null 2>&1 || need+=("$p")
done
if [ ${#need[@]} -gt 0 ]; then
  apt-get update -qq
  apt-get install -y -qq "${need[@]}"
else
  echo "  all present"
fi

log "2/6 Code → ${WEBROOT} (${BRANCH})"
if [ -d "${WEBROOT}/.git" ]; then
  git -C "${WEBROOT}" fetch --quiet origin "${BRANCH}"
  git -C "${WEBROOT}" reset --quiet --hard "origin/${BRANCH}"
else
  mkdir -p "${WEBROOT}"
  git clone --quiet --branch "${BRANCH}" "${REPO}" "${WEBROOT}"
fi
SHA="$(git -C "${WEBROOT}" rev-parse --short HEAD)"
echo "  at ${SHA}"
# Webroot must be world-readable for nginx (www-data); .git is blocked by nginx.
chown -R root:root "${WEBROOT}"
find "${WEBROOT}" -type d -exec chmod 755 {} +
find "${WEBROOT}" -type f -exec chmod 644 {} +

log "3/6 TLS certificate"
if [ ! -s "${CERT_DIR}/fullchain.pem" ]; then
  echo "  no certificate yet — issuing via webroot on port 80"
  cat > "${NGINX_CONF}" <<BOOT
server {
    listen 80; listen [::]:80;
    server_name ${DOMAIN} ${WWW};
    root ${WEBROOT};
    location ^~ /.well-known/acme-challenge/ { default_type "text/plain"; }
    location / { return 503; }
}
BOOT
  ln -sf "${NGINX_CONF}" /etc/nginx/sites-enabled/flowra
  nginx -t && systemctl reload nginx
  certbot certonly --webroot -w "${WEBROOT}" -d "${DOMAIN}" -d "${WWW}" \
    --non-interactive --agree-tos -m "${CERT_EMAIL}"
else
  echo "  present ($(openssl x509 -enddate -noout -in "${CERT_DIR}/fullchain.pem"))"
fi
# certbot-nginx normally creates these; make sure they exist for the include lines.
[ -s /etc/letsencrypt/options-ssl-nginx.conf ] || \
  curl -fsSL https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf \
    -o /etc/letsencrypt/options-ssl-nginx.conf
[ -s /etc/letsencrypt/ssl-dhparams.pem ] || \
  openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048

log "4/6 nginx vhost from repo nginx.conf"
install -m 644 "${WEBROOT}/nginx.conf" "${NGINX_CONF}"
ln -sf "${NGINX_CONF}" /etc/nginx/sites-enabled/flowra
nginx -t || die "nginx config test FAILED — site config NOT reloaded. Fix nginx.conf in the repo and redeploy."
systemctl reload nginx

log "5/6 Verify the live site serves this commit"
sleep 1
LIVE_SUM="$(curl -fsS --max-time 20 "https://${WWW}/" | sha256sum | cut -d' ' -f1)"
REPO_SUM="$(sha256sum "${WEBROOT}/index.html" | cut -d' ' -f1)"
if [ "${LIVE_SUM}" = "${REPO_SUM}" ]; then
  echo "  OK — live index.html matches ${SHA}"
else
  die "live index.html does NOT match the deployed file. Check nginx root / caching."
fi

log "6/6 Smoke check"
bash "${WEBROOT}/scripts/smoke-check.sh"

printf '\n✅ Deployed %s to https://%s\n' "${SHA}" "${WWW}"
