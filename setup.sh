#!/bin/bash
# One-time setup: creates 'bedtime' group in Pi-hole and adds catch-all deny rule.
# Run once as root. Does not modify Xfinity router or existing Pi-hole data.

set -e

GRAVITY_DB="/DATA/AppData/pihole/etc/pihole/gravity.db"

echo "[bedtime-setup] Creating 'bedtime' group in Pi-hole..."
sqlite3 "$GRAVITY_DB" <<'EOF'
-- Create the bedtime group (disabled by default so daytime is unaffected)
INSERT OR IGNORE INTO "group" (name, enabled, description)
VALUES ('bedtime', 0, 'Devices blocked during nighttime hours (22:30-05:30)');

-- Add catch-all regex deny rule
INSERT OR IGNORE INTO domainlist (type, domain, enabled, comment)
VALUES (3, '.*', 1, 'Bedtime catch-all: blocks all DNS for restricted devices');

-- Assign the catch-all deny ONLY to the bedtime group
-- (so it does NOT affect Default group clients)
INSERT OR IGNORE INTO domainlist_by_group (domainlist_id, group_id)
SELECT d.id, g.id
FROM domainlist d, "group" g
WHERE d.domain = '.*' AND d.type = 3 AND g.name = 'bedtime';
EOF

echo "[bedtime-setup] Reloading Pi-hole lists..."
docker exec pihole pihole restartdns reload

echo ""
echo "[bedtime-setup] Done. Current groups:"
sqlite3 "$GRAVITY_DB" "SELECT id, name, enabled, description FROM 'group';"
echo ""
echo "[bedtime-setup] Next step: run add-device.sh to register restricted devices."
echo "  Exempt devices need no action — unregistered devices default to the Default group."
