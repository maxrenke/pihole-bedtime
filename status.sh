#!/bin/bash
# Show current bedtime enforcement status.

GRAVITY_DB="/DATA/AppData/pihole/etc/pihole/gravity.db"

ENABLED=$(sqlite3 "$GRAVITY_DB" "SELECT enabled FROM \"group\" WHERE name='bedtime';")

if [[ "$ENABLED" == "1" ]]; then
  echo "Status: BEDTIME ACTIVE (DNS blocking enabled)"
elif [[ "$ENABLED" == "0" ]]; then
  echo "Status: BEDTIME LIFTED (normal access)"
else
  echo "Status: bedtime group not found — run setup.sh first"
fi

echo ""
echo "Bedtime-restricted devices:"
sqlite3 "$GRAVITY_DB" "
  SELECT c.ip, c.comment
  FROM client c
  JOIN client_by_group cbg ON c.id = cbg.client_id
  JOIN \"group\" g ON cbg.group_id = g.id
  WHERE g.name = 'bedtime'
  ORDER BY c.ip;
"

echo ""
echo "Recent log entries:"
tail -10 /var/log/bedtime.log 2>/dev/null || echo "(no log yet)"
