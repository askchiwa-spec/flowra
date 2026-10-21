#!/usr/bin/env bash
# Post-deploy smoke check for https://www.flowratech.com
# Run from anywhere:  bash scripts/smoke-check.sh
# Exits non-zero on the first class of failure, prints every check.
set -uo pipefail

HOST="www.flowratech.com"
APEX="flowratech.com"
BASE="https://${HOST}"
fail=0
pass() { printf '  ✓ %s\n' "$*"; }
bad()  { printf '  ✗ %s\n' "$*"; fail=1; }
code() { curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$@"; }
hdrs() { curl -sI --max-time 20 "$1" | tr -d '\r' | tr 'A-Z' 'a-z'; }

echo "── Redirects"
[ "$(code "http://${APEX}/")"  = 301 ] && pass "http apex → 301"  || bad "http apex not 301"
[ "$(code "http://${HOST}/")"  = 301 ] && pass "http www → 301"   || bad "http www not 301"
[ "$(code "https://${APEX}/")" = 301 ] && pass "https apex → 301" || bad "https apex not 301 (canonical is www)"
loc="$(curl -sI --max-time 20 "https://${APEX}/x?y=1" | tr -d '\r' | awk 'tolower($1)=="location:"{print $2}')"
[ "$loc" = "https://${HOST}/x?y=1" ] && pass "apex redirect keeps path+query" || bad "apex redirect target: ${loc:-none}"

echo "── Homepage"
[ "$(code "${BASE}/")" = 200 ] && pass "www / → 200" || bad "www / not 200"
H="$(hdrs "${BASE}/")"
for h in "strict-transport-security: max-age=31536000" \
         "x-frame-options: sameorigin" \
         "x-content-type-options: nosniff" \
         "referrer-policy: strict-origin-when-cross-origin" \
         "permissions-policy:" \
         "cross-origin-opener-policy: same-origin" \
         "content-security-policy: default-src 'self'"; do
  echo "$H" | grep -q "^${h}" && pass "header ${h%%:*}" || bad "missing header: ${h}"
done
echo "$H" | grep -q "includesubdomains" && bad "HSTS includeSubDomains is ON (should be off)" || pass "HSTS without includeSubDomains"
echo "$H" | grep -qE '^server: nginx/[0-9]' && bad "nginx version disclosed" || pass "server_tokens off"
echo "$H" | grep -q '^cache-control: no-cache' && pass "html no-cache" || bad "html cache-control not no-cache"

echo "── Outreach tracking endpoints"
[ "$(code "${BASE}/o/0123456789ab.gif")" = 404 ] && pass "open pixel rejects wrong id length" || bad "open pixel accepted a bad id"
[ "$(code "${BASE}/o/0123456789.gif")" = 200 ] && pass "open pixel /o/<id>.gif → 200" || bad "open pixel not 200"
T="$(hdrs "${BASE}/o/0123456789.gif")"
echo "$T" | grep -q '^content-type: image/gif' && pass "open pixel is image/gif" || bad "open pixel content-type wrong"
echo "$T" | grep -q '^cache-control: no-cache' && pass "open pixel no-cache" || bad "open pixel is cacheable"
[ "$(code "${BASE}/go/0123456789/demo")" = 302 ] && pass "/go/<id>/demo → 302" || bad "/go/<id>/demo not 302"
loc="$(curl -sI --max-time 20 "${BASE}/go/0123456789/demo" | tr -d '\r' | awk 'tolower($1)=="location:"{print $2}')"
[ "$loc" = "https://calendly.com/askchiwa/30min" ] && pass "demo redirect → Calendly" || bad "demo redirect target: ${loc:-none}"
[ "$(code "${BASE}/go/0123456789/pricing")" = 302 ] && pass "/go/<id>/pricing → 302" || bad "/go/<id>/pricing not 302"
[ "$(code "${BASE}/go/0123456789/growth")" = 302 ] && pass "/go/<id>/growth → 302" || bad "/go/<id>/growth not 302"
[ "$(code "${BASE}/go/0123456789/other")" = 404 ] && pass "unknown /go target → 404" || bad "unknown /go target not 404"

echo "── Exposure"
for p in deploy.sh README.md nginx.conf .gitignore .git/HEAD .git/config scripts/smoke-check.sh; do
  c="$(code "${BASE}/${p}")"
  [ "$c" = 404 ] || [ "$c" = 403 ] && pass "${p} → ${c}" || bad "${p} → ${c} (should be 404)"
done
[ "$(code "${BASE}/this-page-does-not-exist-$RANDOM")" = 404 ] && pass "unknown path → 404 (no SPA fallback)" || bad "unknown path not 404"

echo "── Assets"
for p in css/styles.css css/animations.css js/main.js images/flowra-logo-160.webp images/hero-bg.webp images/lion-watermark.webp images/favicon.png images/growth-engine.webp growth-engine.html watu-hcm.html 404.html; do
  [ "$(code "${BASE}/${p}")" = 200 ] && pass "${p} 200" || bad "${p} not 200"
done

echo "── TLS"
for v in 1.0 1.1; do
  if echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" -tls1_${v/./_} >/dev/null 2>&1; then
    bad "TLS ${v} accepted"; else pass "TLS ${v} refused"; fi
done
echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" -tls1_3 2>/dev/null | grep -q 'TLSv1.3' && pass "TLS 1.3 works" || bad "TLS 1.3 not negotiated"
exp="$(echo | openssl s_client -connect "${HOST}:443" -servername "${HOST}" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)"
if [ -n "$exp" ]; then
  exp_s=$(date -j -f '%b %e %T %Y %Z' "$exp" +%s 2>/dev/null || date -d "$exp" +%s 2>/dev/null)
  days=$(( (exp_s - $(date +%s)) / 86400 ))
  [ "$days" -gt 14 ] && pass "certificate valid ${days}d" || bad "certificate expires in ${days}d"
fi

echo "── Deploy drift"
here="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "${here}/index.html" ]; then
  live="$(curl -s --max-time 20 "${BASE}/" | shasum -a 256 | cut -d' ' -f1)"
  repo="$(shasum -a 256 "${here}/index.html" | cut -d' ' -f1)"
  [ "$live" = "$repo" ] && pass "live index.html == local index.html" || bad "live index.html differs from local (undeployed or stale)"
fi

echo
[ $fail -eq 0 ] && echo "✅ smoke check passed" || { echo "❌ smoke check FAILED"; exit 1; }
