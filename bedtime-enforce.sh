#!/bin/bash
# Enable bedtime DNS blocking.
# Called by cron at 22:30 nightly.

set -e

GRAVITY_DB="/DATA/AppData/pihole/etc/pihole/gravity.db"
LOG="/var/log/bedtime.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] bedtime-enforce: activating restrictions" >> "$LOG"

sqlite3 "$GRAVITY_DB" \
  "UPDATE \"group\" SET enabled=1, date_modified=cast(strftime('%s','now') as int) WHERE name='bedtime';"

docker exec pihole pihole restartdns reload

echo "[$(date '+%Y-%m-%d %H:%M:%S')] bedtime-enforce: done" >> "$LOG"
