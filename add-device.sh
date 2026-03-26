#!/bin/bash
# Register a device as bedtime-restricted.
# Usage: ./add-device.sh <IP_or_MAC> [comment]
# Example: ./add-device.sh 10.0.0.42 "kids-tablet"
# Example: ./add-device.sh AA:BB:CC:DD:EE:FF "kids-ipad"

set -e

GRAVITY_DB="/DATA/AppData/pihole/etc/pihole/gravity.db"

if [[ -z "$1" ]]; then
  echo "Usage: $0 <IP_or_MAC> [comment]"
  exit 1
fi

DEVICE="$1"
COMMENT="${2:-added by bedtime script}"

echo "[add-device] Registering device: $DEVICE ($COMMENT)"

sqlite3 "$GRAVITY_DB" <<EOF
-- Add the client entry (ip field accepts both IP addresses and MAC addresses)
INSERT OR IGNORE INTO client (ip, comment)
VALUES ('$DEVICE', '$COMMENT');

-- Ensure it's in the Default group (for normal adblocking during daytime)
INSERT OR IGNORE INTO client_by_group (client_id, group_id)
SELECT c.id, g.id
FROM client c, "group" g
WHERE c.ip = '$DEVICE' AND g.name = 'Default';

-- Assign to bedtime group (blocked when bedtime group is enabled)
INSERT OR IGNORE INTO client_by_group (client_id, group_id)
SELECT c.id, g.id
FROM client c, "group" g
WHERE c.ip = '$DEVICE' AND g.name = 'bedtime';
EOF

echo "[add-device] Reloading Pi-hole lists..."
docker exec pihole pihole restartdns reload

echo "[add-device] Done. Device $DEVICE is now bedtime-restricted."
echo ""
echo "Current bedtime-restricted devices:"
sqlite3 "$GRAVITY_DB" "
  SELECT c.ip, c.comment
  FROM client c
  JOIN client_by_group cbg ON c.id = cbg.client_id
  JOIN \"group\" g ON cbg.group_id = g.id
  WHERE g.name = 'bedtime'
  ORDER BY c.ip;
"
