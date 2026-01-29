#!/usr/bin/env bash
set -euo pipefail

TO_EMAIL="__TO_EMAIL__"
HOME_BASE="__HOME_BASE__"
LOG_DIR="/var/log/imunify"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/lessheadache-$(date '+%Y-%m-%d').log"

if command -v imunify360-agent >/dev/null 2>&1; then
  IMU="imunify360-agent"
elif command -v imunify-antivirus >/dev/null 2>&1; then
  IMU="imunify-antivirus"
else
  exit 0
fi

INFECTED_JSON="$($IMU malware malicious list --by-status found --json 2>/dev/null || true)"

USERS=$(echo "$INFECTED_JSON" | grep -o "$HOME_BASE/[^/]*/public_html" | awk -F'/' '{print $3}' | sort -u)

for u in $USERS; do
  /usr/local/bin/wp-core-refresh "$u" >> "$LOG_FILE" 2>&1 || true
done

echo "LESSHEADACHE executado em $(date)" | mail -s "[LESSHEADACHE] Execução automática" "$TO_EMAIL"
