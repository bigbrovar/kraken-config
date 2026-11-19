#!/usr/bin/env bash
# Compares every homelab hostname through ingress-nginx and through Traefik.
# A host passes when both return the same HTTP status and Traefik sends HSTS.
#
#   ./hack/traefik-migration-check.sh
#
# Nothing is changed. DNS is bypassed with curl --resolve.
set -u

NGINX_IP="${NGINX_IP:-172.42.1.10}"
TRAEFIK_IP="${TRAEFIK_IP:-172.42.1.11}"
UA="Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0"

HOSTS=(
  actual alertmanager argo books checkrr grafana influxdb jellyseerr
  lidarr loki longhorn prowlarr radarr rana search sonarr
)

probe() { # ip host -> "status hsts"
  local headers
  headers=$(curl -s -o /dev/null -D - --max-time 15 \
    -A "$UA" -H "Accept: text/html" -H "Accept-Language: en" -H "Accept-Encoding: gzip" \
    --resolve "$2:443:$1" "https://$2/" 2>/dev/null)
  local status hsts=no
  status=$(printf '%s' "$headers" | awk 'NR==1{print $2}')
  printf '%s' "$headers" | grep -qi '^strict-transport-security:' && hsts=yes
  echo "${status:-ERR} $hsts"
}

fail=0
printf '%-32s %-7s %-8s %-5s %s\n' HOST NGINX TRAEFIK HSTS RESULT
for h in "${HOSTS[@]}"; do
  host="$h.homelab.org.ng"
  read -r n_status _ <<<"$(probe "$NGINX_IP" "$host")"
  read -r t_status t_hsts <<<"$(probe "$TRAEFIK_IP" "$host")"
  result=PASS
  if [[ "$t_status" == ERR || "$n_status" != "$t_status" || "$t_hsts" != yes ]]; then
    result=FAIL
    fail=1
  fi
  printf '%-32s %-7s %-8s %-5s %s\n' "$host" "$n_status" "$t_status" "$t_hsts" "$result"
done

redirect=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
  --resolve "grafana.homelab.org.ng:80:$TRAEFIK_IP" http://grafana.homelab.org.ng/)
echo
echo "HTTP to HTTPS redirect through Traefik: $redirect (expect 301 or 308)"
[[ "$redirect" == 301 || "$redirect" == 308 ]] || fail=1

if [[ $fail -eq 0 ]]; then echo "ALL PASS"; else echo "SOME CHECKS FAILED"; fi
exit $fail
