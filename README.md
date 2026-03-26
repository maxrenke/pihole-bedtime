# Bedtime Network Access Control

Scheduled DNS-based internet blocking via Pi-hole. Blocks restricted devices at 22:30, lifts at 05:30. Exempt devices (servers, backup jobs, etc.) are unaffected.

**Inspired by**: https://ratfactor.com/openbsd/pf-gateway-bedtime
**Mechanism**: Pi-hole group with a catch-all `.*` regex deny rule, toggled by cron.

---

## Getting Started

1. **Configure Xfinity DHCP** — log into http://10.0.0.1, set Primary DNS to `10.0.0.249` (no secondary DNS, or set secondary to the same IP)
2. **Run one-time setup**: `sudo /home/casaos/bedtime/setup.sh`
3. **Add restricted devices**: `sudo /home/casaos/bedtime/add-device.sh 10.0.0.XX "device-name"`
4. **Install cron schedule** — create `/etc/cron.d/bedtime` with:
   ```
   30 22 * * *  root  /home/casaos/bedtime/bedtime-enforce.sh
   30 5  * * *  root  /home/casaos/bedtime/bedtime-lift.sh
   ```
5. **Test manually**: run `sudo /home/casaos/bedtime/bedtime-enforce.sh` and verify DNS fails on a restricted device, then `sudo /home/casaos/bedtime/bedtime-lift.sh` to restore

---

## Prerequisites

Before scripts will work, the Xfinity router's DHCP must hand out `10.0.0.249` as the DNS server for all clients. Log into http://10.0.0.1 → DHCP settings → set Primary DNS to `10.0.0.249`. Do NOT set a secondary DNS like 8.8.8.8 (devices would bypass Pi-hole).

---

## One-time Setup

```bash
sudo ./setup.sh
```

Creates the `bedtime` group and catch-all deny rule in Pi-hole's database.

---

## Managing Devices

```bash
# Add a device to the restricted list (blocked at night)
sudo ./add-device.sh 10.0.0.42 "kids-tablet"
sudo ./add-device.sh AA:BB:CC:DD:EE:FF "kids-laptop"   # MAC address works too

# Remove a device from restrictions
sudo ./remove-device.sh 10.0.0.42

# List all devices and group memberships
./list-devices.sh
```

**Exempt devices need no action.** Devices not registered in Pi-hole's client list default to the Default group only and are unaffected by bedtime restrictions.

**MAC addresses are supported and preferred.** Pi-hole's client table accepts both IPs and MACs. Pi-hole identifies clients by MAC when possible (via ARP), so even if a device gets a new DHCP lease, the rule follows it. Using MACs is the right call for any device that doesn't have a static IP.

```bash
sudo ./add-device.sh AA:BB:CC:DD:EE:FF "kids-laptop"
```

To find MACs for your devices:
```bash
arp -n      # shows IP → MAC for currently active devices
ip neigh    # same, slightly more detail
```

Or check the Xfinity router's connected devices page — it usually lists both IP and MAC for everything on the network.

---

## Manual Control

```bash
sudo ./bedtime-enforce.sh   # activate blocking now
sudo ./bedtime-lift.sh      # lift blocking now
./status.sh                 # check current state
```

---

## Cron Schedule

Managed via `/etc/cron.d/bedtime`:

```
30 22 * * *  root  /home/casaos/bedtime/bedtime-enforce.sh
30 5  * * *  root  /home/casaos/bedtime/bedtime-lift.sh
```

---

## Logs

```bash
tail -f /var/log/bedtime.log
```

---

## Known Limitations

- **Bypassable**: Devices with hardcoded DNS (8.8.8.8) skip Pi-hole entirely.
- **Active connections not killed**: Existing streams/connections continue until the next DNS lookup. Full connection-killing requires the server to be in the routing path (needs a second NIC).
- **Use MAC addresses** for DHCP clients rather than IPs, or set DHCP reservations in the Xfinity router to keep IPs stable.
