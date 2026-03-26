#!/bin/bash
# Remove a device from bedtime restrictions (removes from bedtime group only).
# Usage: ./remove-device.sh <IP_or_MAC>

set -e

GRAVITY_DB="/DATA/AppData/pihole/etc/pihole/gravity.db"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <IP_or_MAC>"
  exit 1
fi

DEVICE="$1"

echo "[remove-device] Removing $DEVICE from bedtime group..."

sqlite3 "$GRAVITY_DB" <<EOF
DELETE FROM client_by_group
WHERE client_id = (SELECT id FROM client WHERE ip = '$DEVICE')
  AND group_id  = (SELECT id FROM "group" WHERE name = 'bedtime');
EOF

echo "[remove-device] Reloading Pi-hole lists..."
docker exec pihole pihole restartdns reload

echo "[remove-device] Done. $DEVICE is no longer bedtime-restricted."
