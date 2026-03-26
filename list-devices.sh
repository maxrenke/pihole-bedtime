#!/bin/bash
# Show Pi-hole clients and their group assignments.

GRAVITY_DB="/DATA/AppData/pihole/etc/pihole/gravity.db"

echo "=== Pi-hole groups ==="
sqlite3 "$GRAVITY_DB" "SELECT id, name, enabled, description FROM 'group';"
echo ""

echo "=== Bedtime-restricted devices ==="
sqlite3 "$GRAVITY_DB" "
  SELECT c.ip, c.comment
  FROM client c
  JOIN client_by_group cbg ON c.id = cbg.client_id
  JOIN \"group\" g ON cbg.group_id = g.id
  WHERE g.name = 'bedtime'
  ORDER BY c.ip;
"
echo ""

echo "=== All registered clients and their groups ==="
sqlite3 "$GRAVITY_DB" "
  SELECT c.ip, c.comment, GROUP_CONCAT(g.name, ', ') AS groups
  FROM client c
  JOIN client_by_group cbg ON c.id = cbg.client_id
  JOIN \"group\" g ON cbg.group_id = g.id
  GROUP BY c.id
  ORDER BY c.ip;
"
